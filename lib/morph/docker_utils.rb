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

    def self.create_tar(directory)
      tempfile = Tempfile.new('morph_tar')

      # We used to use Archive::Tar::Minitar but that doesn't support
      # symbolic links in the tar file. So, using tar from the command line
      # instead.
      `tar cf #{tempfile.path} -C #{directory} .`
      content = File.open(tempfile.path, 'rb') { |f| f.read }
      FileUtils.rm_f(tempfile.path)
      content
    end

    def self.extract_tar(content, directory)
      # Use ascii-8bit as the encoding to ensure that the binary data isn't
      # changed on saving
      tmp = Tempfile.new('morph.tar', Dir.tmpdir, encoding: 'ASCII-8BIT')
      tmp << content
      tmp.close
      # Quick and dirty
      `tar xf #{tmp.path} -C #{directory}`
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

    # Finds the first matching container
    # Returns nil otherwise
    def self.find_container_with_label(key, value)
      Docker::Container.all(all: true).find do |c|
        c.info['Labels'][key] == value
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
      tar = ''
      # TODO: Don't concatenate this tarfile in memory. It could get big
      begin
        container.copy(path) { |chunk| tar += chunk }
      rescue Docker::Error::ServerError
        # If the path isn't found
        return nil
      end
      # Now extract the tar file and return the contents of the file
      Dir.mktmpdir('morph') do |dest|
        Morph::DockerUtils.extract_tar(tar, dest)
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
  end
end
