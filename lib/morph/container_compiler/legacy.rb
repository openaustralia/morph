module Morph
  module ContainerCompiler
    class Legacy < Base
      def self.compile_and_run(run)
        wrapper = Multiblock.wrapper
        yield(wrapper)

        image = get_or_pull_image(docker_image(run.language)) do |on|
          on.log {|s,c| wrapper.call(:log, :internalout, c)}
        end

        command = Metric.command(run.language.scraper_command, Run.time_output_filename)
        env_variables = run.scraper ? run.scraper.variables.map{|v| [v.name, v.value]} : []
        status_code = Morph::DockerRunner.run(
          command: command,
          user: "scraper",
          image_name: image.id,
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

      def self.stop(run)
        Morph::DockerRunner.stop(docker_container_name(run))
      end

      def self.docker_image(language)
        "openaustralia/morph-#{language.key}"
      end
    end
  end
end
