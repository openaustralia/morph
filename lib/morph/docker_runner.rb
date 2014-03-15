module Morph
  class DockerRunner
    def self.run(options)
      Docker.options[:read_timeout] = 4.hours
      Docker.options[:chunk_size] = 1

      # This will fail if there is another container with the same name
      begin
        c = Docker::Container.create("Cmd" => ['/bin/bash', '-l', '-c', options[:command]],
          "User" => "scraper",
          "Image" => options[:image_name],
          "name" => options[:container_name],
          # See explanation in https://github.com/openaustralia/morph/issues/242
          "CpuShares" => 307,
          # Memory limit (in bytes)
          # On a 1G machine we're allowing a max of 10 containers to run at a time. So, 100M
          "Memory" => 100 * 1024 * 1024)
      rescue Excon::Errors::SocketError => e
        yield :internal, "Morph internal error: Could not connect to Docker server: #{e}\n"
        yield :internal, "Requeueing...\n"
        raise "Could not connect to Docker server: #{e}"
      end

      # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
      # HACK on OS X we're expecting to use Vagrant
      local_root_path = RUBY_PLATFORM.downcase.include?('darwin') ? "/vagrant" : Rails.root

      begin
        c.start("Binds" => [
          "#{local_root_path}/#{options[:repo_path]}:/repo:ro",
          "#{local_root_path}/#{options[:data_path]}:/data"
        ])
        puts "Running docker container..."
        c.attach(logs: true) do |s,c|
          yield s,c
        end
        status_code = c.json["State"]["ExitCode"]
        puts "Docker container finished..."
      rescue Exception => e
        yield :internal, "Morph internal error: #{e}\n"
        yield :internal, "Stopping current container and requeueing\n"
        c.kill
        raise e
      ensure
        # Wait until container has definitely stopped
        c.wait
        # Clean up after ourselves
        c.delete
      end

      status_code
    end

    def self.container_exists?(name)
      begin
        Docker::Container.get(name)
        true
      rescue Docker::Error::NotFoundError => e
        false
      end
    end
  end
end
