module Morph
  class ContainerCompiler
    def self.compile_and_run_original(run)
      command = Metric.command(Morph::Language.scraper_command(run.language), Run.time_output_filename)
      status_code = Morph::DockerRunner.run(
        command: command,
        user: "scraper",
        image_name: run.docker_image,
        container_name: run.docker_container_name,
        repo_path: run.repo_path,
        data_path: run.data_path,
        env_variables: run.scraper.variables.map{|v| [v.name, v.value]}
      ) do |on|
          on.log { |s,c| yield s, c}
          on.ip_address do |ip|
            # Store the ip address of the container for this run
            run.update_attributes(ip_address: ip)
          end
      end
    end

    def self.compile_and_run_with_buildpacks(run)
      # Compile the container
      i = Docker::Image.get('openaustralia/buildstep')
      # Insert the configuration part of the application code into the container
      tar_path = run.tar_config_files
      hash = Digest::SHA2.hexdigest(File.read(tar_path))

      # Check if compiled image already exists
      begin
        i = Docker::Image.get("compiled_#{hash}")
        exists = true
      rescue Docker::Error::NotFoundError
        exists = false
      end

      unless exists
        # TODO insert_local produces a left-over container. Fix this.
        i2 = i.insert_local('localPath' => tar_path, 'outputPath' => '/app')
        i2.tag('repo' => "compiled_#{hash}")
        FileUtils.rm_f(tar_path)

        c = Morph::DockerRunner.run_no_cleanup(
          command: "/build/builder",
          user: "root",
          image_name: "compiled_#{hash}",
          env_variables: {CURL_TIMEOUT: 180}
        ) do |on|
          on.log { |s,c| yield s, c}
        end
        c.commit('repo' => "compiled_#{hash}")
        c.delete
      end

      # Insert the actual code into the container
      i = Docker::Image.get("compiled_#{hash}")
      tar_path = run.tar_run_files
      # TODO insert_local produces a left-over container. Fix this.
      i2 = i.insert_local('localPath' => tar_path, 'outputPath' => '/app')
      i2.tag('repo' => "compiled2_#{run.id}")
      FileUtils.rm_f(tar_path)

      command = Metric.command("/start scraper", "/data/" + Run.time_output_filename)
      status_code = Morph::DockerRunner.run(
        command: command,
        # TODO Need to run this as the user scraper again
        user: "root",
        image_name: "compiled2_#{run.id}",
        container_name: run.docker_container_name,
        data_path: run.data_path,
        env_variables: run.scraper.variables.map{|v| [v.name, v.value]}
      ) do |on|
          on.log { |s,c| yield s, c}
          on.ip_address do |ip|
            # Store the ip address of the container for this run
            run.update_attributes(ip_address: ip)
          end
      end

      i = Docker::Image.get("compiled2_#{run.id}")
      i.delete
    end
  end
end
