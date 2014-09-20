module Morph
  class ContainerCompiler
    def self.docker_container_name(run)
      "#{run.owner.to_param}_#{run.name}_#{run.id}"
    end

    def self.compile_and_run_original(run)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      command = Metric.command(run.language.scraper_command, Run.time_output_filename)
      env_variables = run.scraper ? run.scraper.variables.map{|v| [v.name, v.value]} : []
      status_code = Morph::DockerRunner.run(
        command: command,
        user: "scraper",
        image_name: run.language.docker_image,
        container_name: docker_container_name(run),
        repo_path: run.repo_path,
        data_path: run.data_path,
        env_variables: env_variables
      ) do |on|
          on.log {|s,c| wrapper.call(:log, s, c)}
          on.ip_address {|ip| wrapper.call(:ip_address, ip)}
      end
      status_code
    end

    # file_environment needs to also include a Dockerfile with content
    def self.docker_build_from_files(file_environment)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      result = nil
      dir = Dir.mktmpdir("morph")
      begin
        file_environment.each do |file, content|
          path = File.join(dir, file)
          File.open(path, "w") {|f| f.write content}
          # Set an arbitrary & fixed modification time on the files so that if
          # content is the same it will cache
          FileUtils.touch(path, mtime: Time.new(2000,1,1))
        end
        conn_interactive = Docker::Connection.new(ENV["DOCKER_URL"] || Docker.default_socket_url, {read_timeout: 4.hours})
        begin
          result = Docker::Image.build_from_dir(dir, {'rm' => 1}, conn_interactive) do |chunk|
            # TODO Do this properly
            begin
              wrapper.call(:log, :stdout, JSON.parse(chunk)["stream"])
            rescue JSON::ParserError
              # Workaround until we handle this properly
            end
          end
        rescue Docker::Error::UnexpectedResponseError
          result = nil
        end
      ensure
        FileUtils.remove_entry_secure dir
      end
      result
    end

    # file_environment is a hash of files (and their contents) to put in the same directory
    # as the Dockerfile created to contain the command
    # Returns the new image
    def self.docker_build_command(image, commands, file_environment)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      commands = [commands] unless commands.kind_of?(Array)

      file_environment["Dockerfile"] = "from #{image.id}\n" + commands.map{|c| c + "\n"}.join
      docker_build_from_files(file_environment) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
      end
    end

    def self.compile(repo_path)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      i = Docker::Image.get('openaustralia/buildstep')
      # Insert the configuration part of the application code into the container and build
      commands = ["ADD code_config.tar /app", "ENV CURL_TIMEOUT 180", "RUN /build/builder"]
      docker_build_command(i, commands, "code_config.tar" => tar_config_files(repo_path)) do |on|
        on.log {|s,c| wrapper.call(:log, :internalout, c)}
      end
    end

    def self.compile_and_run_with_buildpacks(run)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      i1 = compile(run.repo_path) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
      end

      # If something went wrong during the compile and it couldn't finish
      if i1.nil?
        # TODO: Return the status for a compile error
        return 255;
      end

      # Insert the actual code into the container
      i2 = docker_build_command(i1, "add code.tar /app", "code.tar" => tar_run_files(run.repo_path)) do |on|
        on.log {|s,c| wrapper.call(:log, :internalout, c)}
      end

      command = Metric.command("/start scraper", "/data/" + Run.time_output_filename)
      status_code = Morph::DockerRunner.run(
        command: command,
        # TODO Need to run this as the user scraper again
        user: "root",
        image_name: i2.id,
        container_name: run.docker_container_name,
        data_path: run.data_path,
        env_variables: run.scraper.variables.map{|v| [v.name, v.value]}
      ) do |on|
          on.log { |s,c| wrapper.call(:log, s, c)}
          on.ip_address {|ip| wrapper.call(:ip_address, ip)}
      end

      i2.delete("noprune" => 1)
      status_code
    end

    # Contents of a tarfile that contains configuration type files
    # like Gemfile, requirements.txt, etc..
    # This comes from a whitelisted list
    def self.tar_config_files(repo_path)
      create_tar_from_paths(all_config_hash_with_defaults(File.join(Rails.root, repo_path)))
    end

    # Contents of a tarfile that contains everything that isn't a configuration file
    def self.tar_run_files(repo_path)
      create_tar_from_paths(all_run_hash(File.join(Rails.root, repo_path)))
    end

    def self.paths_to_hash(directory, paths)
      hash = {}
      paths.each do |path|
        hash[path] = File.read(File.join(directory, path))
      end
      hash
    end

    def self.create_tar_from_paths(hash)
      dir = Dir.mktmpdir("morph")
      begin
        hash.each do |path, content|
          new_path = File.join(dir, path)
          # Ensure the directory exists (for files in subdirectories)
          FileUtils.mkdir_p(File.dirname(new_path))
          File.open(new_path, "w") {|f| f.write(content)}
          # Set an arbitrary & fixed modification time on the files so that if
          # content is the same it will cache
          FileUtils.touch(new_path, mtime: Time.new(2000,1,1))
        end
        create_tar(dir)
      ensure
        FileUtils.remove_entry_secure dir
      end
    end

    def self.create_tar(directory)
      tempfile = Tempfile.new('morph_tar')

      in_directory(directory) do
        begin
          tar = Archive::Tar::Minitar::Output.new(tempfile.path)
          Find.find(".") do |entry|
            if entry != "."
              Archive::Tar::Minitar.pack_file(entry, tar)
            end
          end
        ensure
          tar.close
        end
      end
      content = File.read(tempfile.path)
      FileUtils.rm_f(tempfile.path)
      content
    end

    def self.all_run_hash(directory)
      paths = all_hash(directory).keys - all_config_hash(directory).keys
      all_hash(directory).select{|path,content| paths.include?(path)}
    end

    # Take all_config_hash and fill in with default files and contents
    # if some things are not available
    def self.all_config_hash_with_defaults(directory)
      hash = all_config_hash(directory)
      language = Morph::Language.language(directory)
      insert_default_files_if_all_absent2(hash, language, language.default_files_to_insert)
    end

    def self.insert_default_files_if_all_absent2(hash, language, files_array)
      files_array.each do |files|
        hash = insert_default_files_if_all_absent(hash, language, files)
      end
      hash
    end

    # If all the files are absent insert them
    def self.insert_default_files_if_all_absent(hash, language, files)
      files = [files] unless files.kind_of?(Array)
      if files.all?{|file| hash[file].nil?}
        files.each do |file|
          hash[file] = language.default_file(file)
        end
      end
      hash
    end

    def self.all_config_hash(directory)
      paths = all_hash(directory).keys & ["Gemfile", "Gemfile.lock", "Procfile", "requirements.txt", "runtime.txt", "composer.json", "composer.lock", "cpanfile"]
      all_hash(directory).select{|path,content| paths.include?(path)}
    end

    # Relative paths to all the files in the given directory (recursive)
    # (except for anything below a directory starting with ".")
    def self.all_hash(directory)
      result = {}
      Find.find(directory) do |path|
        if FileTest.directory?(path)
          if File.basename(path)[0] == ?.
            Find.prune
          end
        else
          result_path = Pathname.new(path).relative_path_from(Pathname.new(directory)).to_s
          result[result_path] = File.read(path)
        end
      end
      result
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
