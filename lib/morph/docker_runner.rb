module Morph
  class DockerRunner
    ALL_CONFIG_FILENAMES = ["Gemfile", "Gemfile.lock", "Procfile", "requirements.txt", "runtime.txt", "composer.json", "composer.lock", "cpanfile"]

    # options: repo_path, container_name, data_path, env_variables
    def self.compile_and_run(options)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      tar_config_files = tar_config_files(options[:repo_path])
      tar_run_files = tar_run_files(options[:repo_path])

      i = compile_step1 do |s,c|
        wrapper.call(:log, s, c)
      end
      i2 = compile_step2(i, tar_config_files) do |s,c|
        wrapper.call(:log, s, c)
      end
      i3 = compile_step3(i2) do |s,c|
        wrapper.call(:log, s, c)
      end

      # If something went wrong during the compile and it couldn't finish
      if i3.nil?
        # TODO: Return the status for a compile error
        return 255;
      end

      i4 = compile_step4(i3, tar_run_files) do |s,c|
        wrapper.call(:log, s, c)
      end

      command = Metric.command("/start scraper", "/data/" + Run.time_output_filename)

      status_code = run(
        command: command,
        image_name: i4.id,
        container_name: options[:container_name],
        data_path: options[:data_path],
        env_variables: options[:env_variables]
      ) do |on|
          on.log { |s,c| wrapper.call(:log, s, c)}
          on.ip_address {|ip| wrapper.call(:ip_address, ip)}
      end

      # There's a potential race condition here where we are trying to delete something
      # that might be used elsewhere. Do the most crude thing and just ignore any errors
      # that deleting might throw up.
      begin
        i4.delete("noprune" => 1)
      # TODO When docker-api gem gets updated Docker::Error::ConfictError will be
      # changed to Docker::Error::ConflictError
      rescue Docker::Error::ConfictError
      end
      status_code
    end

    def self.stop(container_name)
      if container_exists?(container_name)
        c = Docker::Container.get(container_name)
        c.kill
      end
    end

    # Contents of a tarfile that contains everything that isn't a configuration file
    def self.tar_run_files(source)
      Dir.mktmpdir("morph") do |dest|
        write_all_run_to_directory(source, dest)
        Morph::DockerUtils.create_tar(dest)
      end
    end

    # Contents of a tarfile that contains configuration type files
    # like Gemfile, requirements.txt, etc..
    # This comes from a whitelisted list
    def self.tar_config_files(source)
      Dir.mktmpdir("morph") do |dest|
        write_all_config_with_defaults_to_directory(source, dest)
        Morph::DockerUtils.create_tar(dest)
      end
    end

    def self.write_all_config_with_defaults_to_directory(source, dest)
      ALL_CONFIG_FILENAMES.each do |config_filename|
        path = File.join(source, config_filename)
        FileUtils.cp(path, dest) if File.exists?(path)
      end

      # We don't need to check that the language is recognised because
      # the compiler is never called if the language isn't valid
      add_config_defaults_to_directory(dest, Morph::Language.language(source))

      fix_modification_times(dest)
    end

    def self.copy_directory_contents(source, dest)
      FileUtils.cp_r File.join(source, "."), dest
    end

    def self.write_all_run_to_directory(source, dest)
      copy_directory_contents(source, dest)

      ALL_CONFIG_FILENAMES.each do |path|
        FileUtils.rm_f(File.join(dest, path))
      end

      remove_hidden_directories(dest)

      # TODO I don't think I need to this step here
      fix_modification_times(dest)
    end

    # Set an arbitrary & fixed modification time on everything in a directory
    # This ensures that if the content is the same docker will cache
    def self.fix_modification_times(dir)
      Find.find(dir) do |entry|
        FileUtils.touch(entry, mtime: Time.new(2000,1,1))
      end
    end

    def self.update_docker_image!
      Morph::DockerUtils.pull_docker_image("openaustralia/buildstep")
    end

    def self.remove_stopped_containers!
      containers = Docker::Container.all(:all => true)
      containers = containers.select do |c|
        running = c.json["State"]["Running"]
        # Time ago in seconds that this finished
        finished_ago = Time.now - Time::iso8601(c.json["State"]["FinishedAt"])
        # Only show containers that have been stopped for more than 5 minutes
        !running && finished_ago > 5 * 60
      end
      containers.each do |c|
        id = c.id[0..11]
        name = c.info["Names"].first if c.info["Names"]
        finished_ago = Time.now - Time::iso8601(c.json["State"]["FinishedAt"])
        puts "Removing container id: #{id}, name: #{name}, finished: #{finished_ago} seconds ago"
        c.delete
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

    private

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
        # TODO We can just get rid of the line below, right? (because it's the default)
        "User" => "root",
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

    def self.docker_build_from_dir(dir)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      # How does this connection get closed?
      conn_interactive = Docker::Connection.new(ENV["DOCKER_URL"] || Docker.default_socket_url, {read_timeout: 4.hours})
      begin
        Docker::Image.build_from_tar(StringIO.new(Morph::DockerUtils.create_tar(dir)), {'rm' => 1}, conn_interactive) do |chunk|
          # TODO Do this properly
          begin
            wrapper.call(:log, :stdout, JSON.parse(chunk)["stream"])
          rescue JSON::ParserError
            # Workaround until we handle this properly
          end
        end
      rescue Docker::Error::UnexpectedResponseError
        nil
      end
    end

    # file_environment is a hash of files (and their contents) to put in the same directory
    # as the Dockerfile created to contain the command
    # Returns the new image
    # We're effectively tarring everything up twice
    # TODO: Fix this
    def self.docker_build_command(image, commands, file_environment)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      commands = [commands] unless commands.kind_of?(Array)

      file_environment["Dockerfile"] = dockerfile_contents_from_commands(image, commands)
      Dir.mktmpdir("morph") do |dir|
        file_environment.each do |file, content|
          File.open(File.join(dir, file), "w") {|f| f.write content}
        end
        fix_modification_times(dir)
        docker_build_from_dir(dir) do |on|
          on.log {|s,c| wrapper.call(:log, s, c)}
        end
      end
    end

    def self.dockerfile_contents_from_commands(image, commands)
      "from #{image.id}\n" + commands.map{|c| c + "\n"}.join
    end

    def self.compile_step1
      Morph::DockerUtils.get_or_pull_image('openaustralia/buildstep') do |on|
        on.log {|s,c| yield :internalout, c}
      end
    end

    # Insert the configuration part of the application code into the container
    def self.compile_step2(i, code_config_tar)
      yield :internalout, "Injecting configuration and compiling...\n"
      docker_build_command(i,
        ["ADD code_config.tar /app"],
        "code_config.tar" => code_config_tar) do |on|
      end
    end

    # And build
    def self.compile_step3(i)
      docker_build_command(i,
        ["ENV CURL_TIMEOUT 180", "RUN /build/builder"], {}) do |on|
        on.log do |s,c|
          # We don't want to show the standard docker build output
          unless c =~ /^Step \d+ :/ || c =~ /^ ---> / || c =~ /^Removing intermediate container / || c =~ /^Successfully built /
            yield :internalout, c
          end
        end
      end
    end

    # Insert the actual code into the container
    def self.compile_step4(i, code_tar)
      yield :internalout, "Injecting scraper code and running...\n"
      docker_build_command(i, "add code.tar /app", "code.tar" => code_tar) do |on|
        # Note that we're not sending the output of this to the console
        # because it is relatively short running and is otherwise confusing
      end
    end

    def self.add_config_defaults_to_directory(dest, language)
      language.default_files_to_insert.each do |files|
        if files.all?{|file| !File.exists?(File.join(dest, file))}
          files.each do |file|
            FileUtils.cp(language.default_config_file_path(file), File.join(dest, file))
          end
        end
      end

      # Special behaviour for Procfile. We don't allow the user to override this
      FileUtils.cp(language.default_config_file_path("Procfile"), File.join(dest, "Procfile"))
    end

    # Remove directories starting with "."
    # TODO Make it just remove the .git directory in the root and not other hidden directories
    # which people might find useful
    def self.remove_hidden_directories(directory)
      Find.find(directory) do |path|
        FileUtils.rm_rf(path) if FileTest.directory?(path) && File.basename(path)[0] == ?.
      end
    end
  end
end
