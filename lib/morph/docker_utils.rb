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
      content = File.read(tempfile.path)
      FileUtils.rm_f(tempfile.path)
      content
    end

    def self.extract_tar(content, directory)
      tmp = Tempfile.new('morph.tar')
      tmp << content
      tmp.close
      # Quick and dirty
      `tar xf #{tmp.path} -C #{directory}`
      tmp.unlink
    end

    # BEWARE: Not thread safe!
    def self.in_directory(directory)
      cwd = FileUtils.pwd
      FileUtils.cd(directory)
      yield
    ensure
      FileUtils.cd(cwd)
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

    def self.container_exists?(name)
      Docker::Container.get(name)
      true
    rescue Docker::Error::NotFoundError
      false
    end

    def self.stop(container_name)
      if container_exists?(container_name)
        c = Docker::Container.get(container_name)
        c.kill
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
  end
end
