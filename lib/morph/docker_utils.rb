module Morph
  # Utility methods for manipulating docker containers and preparing data
  # to inject into docker containers
  class DockerUtils
    def self.pull_docker_image(image)
      Docker::Image.create('fromImage' => image) do |chunk|
        data = JSON.parse(chunk)
        puts "#{data['status']} #{data['id']} #{data['progress']}"
      end
    end

    # Returns temporary file which it is your responsibility
    # to remove after you're done with it
    def self.create_tar_file(directory)
      temp = Tempfile.new('morph_tar', Dir.tmpdir, encoding: 'ascii-8bit')
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
      tmp = Tempfile.new('morph.tar', Dir.tmpdir, encoding: 'ASCII-8BIT')
      tmp << content
      tmp.close
      extract_tar_file(tmp.path, directory)
      tmp.unlink
    end

    # If image is present locally use that. If it isn't then pull it from
    # the hub. This makes initial setup easier
    # TODO: No need to use Multiblock here really
    def self.get_or_pull_image(name)
      Docker::Image.get(name)
    rescue Docker::Error::NotFoundError
      Docker::Image.create('fromImage' => name) do |chunk|
        data = JSON.parse(chunk)
        yield "#{data['status']} #{data['id']} #{data['progress']}\n"
      end
    end

    def self.label_value(container, label_key)
      container.info['Labels'][label_key] if container.info && container.info['Labels']
    end

    def self.container_has_label_value?(container, key, value)
      label_value(container, key) == value
    end

    # Finds the first matching container
    # Returns nil otherwise
    def self.find_container_with_label(key, value, connection = Docker.connection)
      Docker::Container.all({all: true}, connection).find do |container|
        container_has_label_value?(container, key, value)
      end
    end

    def self.copy_directory_contents(source, dest)
      FileUtils.cp_r File.join(source, '.'), dest
    end

    # Set an arbitrary & fixed modification time on everything in a directory
    # This ensures that if the content is the same docker will cache
    def self.fix_modification_times(dir)
      Find.find(dir) do |entry|
        FileUtils.touch(entry, mtime: Time.new(2000, 1, 1))
      end
    end

    # Copy a single file from a container. Returns a string with the contents
    # of the file. Obviously need to provide a filesystem path within the
    # container
    def self.copy_file(container, path)
      # We're going to create a new connection to the same container
      # to avoid whatever connection settings are being used
      container2 = Docker::Container.get(container.id)

      # Use ascii-8bit as the encoding to ensure that the binary data isn't
      # changed on saving
      # Saving everything directly to a temporary file so we don't have to fill
      # up our memory
      tmp = Tempfile.new('morph.tar', Dir.tmpdir, encoding: 'ASCII-8BIT')
      begin
        container2.copy(path) { |chunk| tmp << chunk }
      rescue Docker::Error::ServerError
        # If the path isn't found
        return nil
      end
      tmp.close

      # Now extract the tar file and return the contents of the file
      Dir.mktmpdir('morph') do |dest|
        extract_tar_file(tmp.path, dest)
        tmp.unlink

        path2 = File.join(dest, Pathname.new(path).basename.to_s)
        File.open(path2, 'rb') { |f| f.read }
      end
    end

    # Get a set of files from a container and return them as a hash
    def self.copy_files(container, paths)
      data = {}
      paths.each do |path|
        data[path] = Morph::DockerUtils.copy_file(container, path)
      end
      data
    end

    def self.stopped_containers
      Docker::Container.all(all: true).select do |c|
        !c.json['State']['Running']
      end
    end

    def self.running_containers
      Docker::Container.all
    end

    def self.docker_build_from_dir(dir, options)
      # How does this connection get closed?
      connection = Docker::Connection.new(
        Docker.url, options.merge(Docker.env_options))
      begin
        buffer = ''
        temp = create_tar_file(dir)
        image = Docker::Image.build_from_tar(
          temp, { 'forcerm' => 1 }, connection) do |chunk|
          buffer += chunk
          while i = buffer.index("\r\n")
            first_part = buffer[0..i - 1]
            buffer = buffer[i + 2..-1]
            parsed_line = JSON.parse(first_part)
            yield parsed_line['stream'] if parsed_line.key?('stream')
          end
        end
        # Cleanup temporary tar file
        FileUtils.rm_f(temp.path)
        image
      # TODO: Why are we catching this exception?
      rescue Docker::Error::UnexpectedResponseError
        nil
      end
    end
  end
end
