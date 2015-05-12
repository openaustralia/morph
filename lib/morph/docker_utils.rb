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

      in_directory(directory) do
        # We used to use Archive::Tar::Minitar but that doesn't support
        # symbolic links in the tar file. So, using tar from the command line
        # instead.
        `tar cf #{tempfile.path} .`
      end
      content = File.read(tempfile.path)
      FileUtils.rm_f(tempfile.path)
      content
    end

    def self.in_directory(directory)
      cwd = FileUtils.pwd
      FileUtils.cd(directory)
      yield
    ensure
      FileUtils.cd(cwd)
    end
  end
end
