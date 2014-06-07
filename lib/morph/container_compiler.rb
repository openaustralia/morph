module Morph
  class ContainerCompiler
    def self.docker_image(language)
      "openaustralia/morph-#{language}"
    end

    def self.docker_container_name(run)
      "#{run.owner.to_param}_#{run.name}_#{run.id}"
    end

    def self.compile_and_run_original(run)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      command = Metric.command(Morph::Language.scraper_command(run.language), Run.time_output_filename)
      status_code = Morph::DockerRunner.run(
        command: command,
        user: "scraper",
        image_name: docker_image(run.language),
        container_name: docker_container_name(run),
        repo_path: run.repo_path,
        data_path: run.data_path,
        env_variables: run.scraper.variables.map{|v| [v.name, v.value]}
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
        result = Docker::Image.build_from_dir(dir, 'rm' => 1) do |chunk|
          wrapper.call(:log, :stdout, JSON.parse(chunk)["stream"])
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
      commands = ["add code_config.tar /app", "run /build/builder"]
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
      create_tar_from_paths(all_config_hash(File.join(Rails.root, repo_path)))
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
          File.open(File.join(dir, path), "w") {|f| f.write(content)}
          # Set an arbitrary & fixed modification time on the files so that if
          # content is the same it will cache
          FileUtils.touch(File.join(dir, path), mtime: Time.new(2000,1,1))
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

    def self.all_config_hash(directory)
      paths = all_hash(directory).keys & ["Gemfile", "Gemfile.lock", "Procfile"]
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
