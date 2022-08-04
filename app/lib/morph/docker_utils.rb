# typed: false
# frozen_string_literal: true

module Morph
  # Utility methods for manipulating docker containers and preparing data
  # to inject into docker containers
  class DockerUtils
    def self.pull_docker_image(image)
      Docker::Image.create("fromImage" => image) do |chunk|
        data = JSON.parse(chunk)
        Rails.logger.info "#{data['status']} #{data['id']} #{data['progress']}"
      end
    end

    # Returns temporary file which it is your responsibility
    # to remove after you're done with it
    def self.create_tar_file(directory)
      temp = Tempfile.new("morph_tar", Dir.tmpdir, encoding: "ascii-8bit")
      # We used to use Archive::Tar::Minitar but that doesn't support
      # symbolic links in the tar file. So, using tar from the command line
      # instead.
      `tar cf #{temp.path} -C #{directory} .`
      temp
    end

    def self.create_tar(directory)
      temp = create_tar_file(directory)
      content = temp.read
      FileUtils.rm_f(temp.path)
      content
    end

    def self.extract_tar_file(path, directory)
      # Quick and dirty
      `tar xf #{path} -C #{directory}`
    end

    def self.extract_tar(content, directory)
      # Use ascii-8bit as the encoding to ensure that the binary data isn't
      # changed on saving
      tmp = Tempfile.new("morph.tar", Dir.tmpdir, encoding: "ASCII-8BIT")
      tmp << content
      tmp.close
      extract_tar_file(tmp.path, directory)
      tmp.unlink
    end

    # If image is present locally use that. If it isn't then pull it from
    # the hub. This makes initial setup easier
    def self.get_or_pull_image(name)
      Docker::Image.get(name)
    rescue Docker::Error::NotFoundError
      Docker::Image.create("fromImage" => name) do |chunk|
        chunk.split("\n").each do |c|
          data = JSON.parse(c)
          Rails.logger.info "#{data['status']} #{data['id']} #{data['progress']}\n"
        end
      end
    end

    def self.label_value(container, label_key)
      container.info["Labels"][label_key] if container.info && container.info["Labels"]
    end

    def self.container_has_label_value?(container, key, value)
      label_value(container, key) == value
    end

    # Finds the first matching container
    # Returns nil otherwise
    def self.find_container_with_label(key, value)
      # TODO: We can use the docker api to do this search
      Docker::Container.all(all: true).find do |container|
        container_has_label_value?(container, key, value)
      end
    end

    def self.find_all_containers_with_label(key)
      Docker::Container.all(all: true, filters: { label: [key.to_s] }.to_json)
    end

    def self.find_all_containers_with_label_and_value(key, value)
      Docker::Container.all(all: true, filters: { label: ["#{key}=#{value}"] }.to_json)
    end

    def self.copy_directory_contents(source, dest)
      FileUtils.cp_r File.join(source, "."), dest
    end

    # Set an arbitrary & fixed modification time on everything in a directory
    # This ensures that if the content is the same docker will cache
    def self.fix_modification_times(dir)
      Find.find(dir) do |entry|
        FileUtils.touch(entry, mtime: Time.zone.local(2000, 1, 1).time)
      end
    end

    # Copy a single file from a container. Returns a temp file with the contents
    # of the file from the container. Obviously need to provide a filesystem
    # path within the container
    def self.copy_file(container, path)
      # Use ascii-8bit as the encoding to ensure that the binary data isn't
      # changed on saving
      # Saving everything directly to a temporary file so we don't have to fill
      # up our memory
      tmp = Tempfile.new("morph.tar", Dir.tmpdir, encoding: "ASCII-8BIT")
      begin
        container.archive_out(path) { |chunk| tmp << chunk }
      rescue Docker::Error::NotFoundError
        # If the path isn't found
        return nil
      end
      tmp.close

      # Now extract the tar file and return the contents of the file
      Dir.mktmpdir("morph") do |dest|
        extract_tar_file(tmp.path, dest)
        tmp.unlink

        path2 = File.join(dest, Pathname.new(path).basename.to_s)
        tmp = Tempfile.new("morph-file")
        FileUtils.cp(path2, tmp.path)
      end
      tmp
    end

    # Get a set of files from a container and return them as a hash of
    # local temporary files
    def self.copy_files(container, paths)
      data = {}
      paths.each do |path|
        data[path] = copy_file(container, path)
      end
      data
    end

    def self.stopped_containers
      Docker::Container.all(all: true).reject do |c|
        c.json["State"]["Running"]
      end
    end

    def self.running_containers
      Docker::Container.all
    end

    def self.docker_build_from_dir(dir, connection_options, build_options = {})
      # How does this connection get closed?
      connection = docker_connection(connection_options)
      temp = create_tar_file(dir)
      buffer = +""
      Docker::Image.build_from_tar(
        temp, build_options.merge("forcerm" => 1), connection
      ) do |chunk|
        # Sometimes a chunk contains multiple lines of json
        chunk.split("\n").each do |line|
          parsed_line = JSON.parse(line)
          next unless parsed_line.key?("stream")

          buffer << parsed_line["stream"]
          # Buffer output until an end-of-line is detected. This
          # makes line output more consistent across platforms.
          # Make sure that buffer can't grow out of control by limiting
          # it's size around 256 bytes
          if buffer[-1..-1] == "\n" || buffer.length >= 256
            yield buffer
            buffer = +""
          end
        end
        yield buffer if buffer != ""
      end
    # This exception gets thrown if there is an error during the build (for
    # example if the compile fails). In this case we just want to return nil
    rescue Docker::Error::UnexpectedResponseError
      nil
    end

    def self.docker_connection(options)
      Docker::Connection.new(Docker.url, Docker.env_options.merge(options))
    end

    # Copy the contents of "src" to the directory dest in the container c
    def self.insert_contents_of_directory(container, src, dest)
      # Rather than using archive_in we're doing this more roundabout way
      # because archive_in seems to have very broken handling of directories
      # TODO Submit a fix to the docker-api gem to fix this
      # In the meantime get something more long-winded working here

      tar_file = Docker::Util.create_dir_tar(src).path
      File.open(tar_file, "rb") do |tar|
        container.archive_in_stream(dest) do
          tar.read(Excon.defaults[:chunk_size]).to_s
        end
      end
      File.delete(tar_file)
    end

    # Inserts a single file into a container.
    # Not using archive_in because that doesn't maintain file permissions
    def self.insert_file(container, src, dest)
      # This is very roundabout
      Dir.mktmpdir("morph") do |tmp_dir|
        FileUtils.cp(src, tmp_dir)
        insert_contents_of_directory(container, tmp_dir, dest)
      end
    end

    # TODO: There's probably a more sensible way of doing this
    def self.image_built_on_other_image?(image, image_base)
      index = image.history.find_index { |l| l["Id"] == image_base.id }
      index&.nonzero?
    end

    # This returns the total size of all the layers down to but not include the
    # base layer. This is a useful way of estimating disk space
    # image should be built on top of image_base.
    def self.disk_space_image_relative_to_other_image(image, image_base)
      layers = image.history
      base_layer_index = layers.find_index { |l| l["Id"] == image_base.id }
      raise "image is not built on top of image_base" if base_layer_index.nil?

      diff_layers = layers[0..base_layer_index - 1]
      diff_layers.map { |l| l["Size"] }.sum
    end

    def self.surpress_warnings(&block)
      verbosity = $VERBOSE
      $VERBOSE = nil
      result = block.call
      $VERBOSE = verbosity
      result
    end

    def self.ip_address_of_container(container)
      container.json["NetworkSettings"]["Networks"].values.first["IPAddress"]
    end
  end
end
