module Morph
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

    # BEWARE: Not thread safe!
    def self.in_directory(directory)
      cwd = FileUtils.pwd
      FileUtils.cd(directory)
      yield
    ensure
      FileUtils.cd(cwd)
    end

    # If image is present locally use that. If it isn't then pull it from the hub
    # This makes initial setup easier
    # TODO No need to use Multiblock here really
    def self.get_or_pull_image(name)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      begin
        Docker::Image.get(name)
      rescue Docker::Error::NotFoundError
        Docker::Image.create('fromImage' => name) do |chunk|
          data = JSON.parse(chunk)
          wrapper.call(:log, :internalout, "#{data['status']} #{data['id']} #{data['progress']}\n")
        end
      end
    end
  end
end
