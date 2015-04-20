module Morph
  class DockerRunner
    # Mandatory: command, image_name, user
    # Optional: env_variables, repo_path, data_path, container_name
    def self.run_no_cleanup(options)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      env_variables = options[:env_variables] || {}

      # Open up a special interactive connection to Docker
      # TODO Cache connection
      conn_interactive = Docker::Connection.new(ENV["DOCKER_URL"] || Docker.default_socket_url, {chunk_size: 1, read_timeout: 4.hours})

      container_options = {
        "Cmd" => ['/bin/bash', '-l', '-c', options[:command]],
        "User" => options[:user],
        "Image" => options[:image_name],
        # See explanation in https://github.com/openaustralia/morph/issues/242
        "CpuShares" => 307,
        # Memory limit (in bytes)
        # On a 1G machine we're allowing a max of 10 containers to run at a time. So, 100M
        "Memory" => 100 * 1024 * 1024,
        "Env" => env_variables.map{|k,v| "#{k}=#{v}"}
      }
      container_options["name"] = options[:container_name] if options[:container_name]

      # This will fail if there is another container with the same name
      begin
        c = Docker::Container.create(container_options, conn_interactive)
      rescue Excon::Errors::SocketError => e
        text = "Could not connect to Docker server: #{e}"
        wrapper.call(:log, :internalerr, "morph.io internal error: #{text}\n")
        wrapper.call(:log, :internalerr, "Requeueing...\n")
        raise text
      rescue Docker::Error::NotFoundError => e
        text = "Could not find docker image #{options[:image_name]}"
        wrapper.call(:log, :internalerr, "morph.io internal error: #{text}\n")
        wrapper.call(:log, :internalerr, "Requeueing...\n")
        raise text
      end

      # TODO the local path will be different if docker isn't running through Vagrant (i.e. locally)
      # HACK on OS X we're expecting to use Vagrant
      local_root_path = RUBY_PLATFORM.downcase.include?('darwin') ? "/vagrant" : Rails.root

      begin
        binds = []
        binds << "#{local_root_path}/#{options[:repo_path]}:/repo:ro" if options[:repo_path]
        binds << "#{local_root_path}/#{options[:data_path]}:/data" if options[:data_path]
        c.start("Binds" => binds)
        puts "Running docker container..."
        # Let parent know about ip address of running container
        wrapper.call(:ip_address, c.json["NetworkSettings"]["IPAddress"])
        c.attach(logs: true) do |s,c|
          # We're going to assume (somewhat rashly, I might add) that the console
          # output from the scraper is always encoded as UTF-8.
          c.force_encoding("UTF-8")
          c.scrub!
          wrapper.call(:log, s, c)
        end
        status_code = c.json["State"]["ExitCode"]
        puts "Docker container finished..."
      rescue Exception => e
        wrapper.call(:log,  :internalerr, "morph.io internal error: #{e}\n")
        wrapper.call(:log, :internalerr, "Stopping current container and requeueing\n")
        c.kill
        raise e
      end
      c
    end

    def self.run(options)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      c = run_no_cleanup(options) do |on|
        on.log { |s,c| wrapper.call(:log, s, c) }
        on.ip_address { |ip| wrapper.call(:ip_address, ip) }
      end
      status_code = c.json["State"]["ExitCode"]
      # Wait until container has definitely stopped
      c.wait
      # Clean up after ourselves
      c.delete

      status_code
    end

    def self.stop(container_name)
      if container_exists?(container_name)
        c = Docker::Container.get(container_name)
        c.kill
      end
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
