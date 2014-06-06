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

    # file_environment is a hash of files (and their contents) to put in the same directory
    # as the Dockerfile created to contain the command
    # Returns the new image
    def self.docker_build_command(image, command, file_environment)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      result = nil
      dir = Dir.mktmpdir("morph")
      begin
        file_environment["Dockerfile"] = "from #{image.id}\n#{command}\n"
        file_environment.each do |file, content|
          path = File.join(dir, file)
          File.open(path, "w") {|f| f.write content}
          # Set an arbitrary & fixed modification time on the files so that if
          # content is the same it will cache
          FileUtils.touch(path, mtime: Time.new(2000,1,1))
        end
        result = Docker::Image.build_from_dir(dir) do |chunk|
          wrapper.call(:log, :stdout, JSON.parse(chunk)["stream"])
        end
      ensure
        FileUtils.remove_entry_secure dir
      end
      result
    end

    def self.compile(repo_path)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      # Compile the container
      i = Docker::Image.get('openaustralia/buildstep')
      # Insert the configuration part of the application code into the container
      tar_path = tar_config_files(repo_path)
      i2 = docker_build_command(i, "add config_tar /app", "config_tar" => File.read(tar_path)) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
      end
      FileUtils.rm_f(tar_path)

      i3 = docker_build_command(i2, "run /build/builder", {}) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
      end

      # Insert the actual code into the container
      tar_path = tar_run_files(repo_path)
      i2 = i3.insert_local('localPath' => tar_path, 'outputPath' => '/app', 'rm' => 1)
      FileUtils.rm_f(tar_path)
      i2
    end

    def self.compile_and_run_with_buildpacks(run)
      wrapper = Multiblock.wrapper
      yield(wrapper)

      i2 = compile(run.repo_path) do |on|
        on.log {|s,c| wrapper.call(:log, s, c)}
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

      #i2.delete
      status_code
    end

    # A path to a tarfile that contains configuration type files
    # like Gemfile, requirements.txt, etc..
    # This comes from a whitelisted list
    # You must clean up this file yourself after you're finished with it
    def self.tar_config_files(repo_path)
      absolute_path = File.join(Rails.root, repo_path)
      create_tar(absolute_path, all_config_paths(absolute_path))
    end

    # A path to a tarfile that contains everything that isn't a configuration file
    # You must clean up this file yourself after you're finished with it
    def self.tar_run_files(repo_path)
      absolute_path = File.join(Rails.root, repo_path)
      create_tar(absolute_path, all_run_paths(absolute_path))
    end

    # Returns the filename of the tar
    # The directory needs to be an absolute path name
    def self.create_tar(directory, paths)
      tempfile = Tempfile.new('morph_tar')

      in_directory(directory) do
        begin
          tar = Archive::Tar::Minitar::Output.new(tempfile.path)
          paths.each do |entry|
            Archive::Tar::Minitar.pack_file(entry, tar)
          end
        ensure
          tar.close
        end
      end
      tempfile.path
    end

    def self.all_config_paths(directory)
      all_paths(directory) & ["Gemfile", "Gemfile.lock", "Procfile"]
    end

    def self.all_run_paths(directory)
      all_paths(directory) - all_config_paths(directory)
    end

    # Relative paths to all the files in the given directory (recursive)
    # (except for anything below a directory starting with ".")
    def self.all_paths(directory)
      result = []
      Find.find(directory) do |path|
        if FileTest.directory?(path)
          if File.basename(path)[0] == ?.
            Find.prune
          end
        else
          result << Pathname.new(path).relative_path_from(Pathname.new(directory)).to_s
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
