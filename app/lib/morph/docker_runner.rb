# typed: false
# frozen_string_literal: true

# To define Sidekiq::Shutdown
require "sidekiq/cli"

module Morph
  # More low-level API for running scrapers. Does not do much of the magic
  # and is less opinionated than the higher-level API in Morph::Runner
  class DockerRunner
    ALL_CONFIG_FILENAMES = [
      "Procfile",
      "Gemfile", "Gemfile.lock",
      "requirements.txt", "runtime.txt",
      "composer.json", "composer.lock",
      "app.psgi", "cpanfile",
      "package.json"
    ].freeze
    BUILDSTEP_IMAGE = "openaustralia/buildstep"
    # Variants of the buildstep image that we're currently supporting. These
    # correspond to tags of the buildstep image
    PLATFORMS = %w[cedar-14 heroku-18].freeze
    DEFAULT_PLATFORM = "cedar-14"
    DOCKER_NETWORK = "morph"
    DOCKER_BRIDGE = "morph"
    DOCKER_NETWORK_SUBNET = "192.168.0.0/16"

    def self.time_file
      "/app/time.output"
    end

    def self.default_memory_limit
      512 * 1024 * 1024
    end

    def self.buildstep_image(platform)
      Morph::DockerUtils.get_or_pull_image("#{BUILDSTEP_IMAGE}:#{platform}")
    end

    # "memory" is the memory limit applied to running container (in bytes). If nil uses the default (set in default_memory_limit)
    def self.compile_and_start_run(
      repo_path:, env_variables: {}, container_labels: {}, max_lines: 0, platform: nil,
      disable_proxy: false, memory: nil
    )
      memory = default_memory_limit if memory.nil?

      i = buildstep_image(platform || DEFAULT_PLATFORM) do |c|
        yield(:internalout, c) if block_given?
      end
      yield(:internalout, "Injecting configuration and compiling...\n") if block_given?
      i3 = compile(i, repo_path) do |c|
        yield(:internalout, c) if block_given?
      end
      # If something went wrong during the compile and it couldn't finish
      return nil if i3.nil?

      # Before we create a container we need to make sure that there is a
      # special network there for it to be put into
      create_morph_network

      command = Morph::TimeCommand.command(
        ["/usr/local/bin/limit_output.rb", max_lines.to_s, "/bin/herokuish procfile start scraper"],
        time_file
      )

      # TODO: Also copy back time output file and the sqlite journal file
      # The sqlite journal file won't be present most of the time

      # Add another label to the created container
      container_labels["io.morph.stage"] = "running"

      # Set up special security profile that allows us run chrome headless
      # without setting "--no-sandbox"
      # The documentation on this is non-existent but
      # the seccomp in the api is not the name of the file but the contents of it
      # In other words the file is uploaded client side
      # From https://raw.githubusercontent.com/jfrazelle/dotfiles/master/etc/docker/seccomp/chrome.json
      # Don't set things in test because it fails on travis for some reason
      security_opt = Rails.env.test? ? [] : ["seccomp=#{File.read('config/chrome.json')}"]

      host_config = {
        "SecurityOpt" => security_opt,
        # Bump up the default shared memory size to 256 MB from the default (64 MB)
        # as an attempt to make headless browsing work properly. See
        # https://medium.com/the-curve-tech-blog/dealing-with-cryptic-selenium-webdriver-error-invalidsessioniderror-errors-9c15abc68fdf
        "ShmSize" => 256 * 1024 * 1024
      }
      # Attach this container to our special network morph
      # But we can optionally disable that if we want to bypass the transparent
      # proxy for outgoing web requests
      host_config["NetworkMode"] = DOCKER_NETWORK unless disable_proxy

      container_options = {
        "Cmd" => command,
        "Image" => i3.id,
        # See explanation in https://github.com/openaustralia/morph/issues/242
        "CpuShares" => 307,
        "Memory" => memory,
        "Env" =>
          {
            "REQUESTS_CA_BUNDLE" => "/etc/ssl/certs/ca-certificates.crt"
          }.merge(env_variables).map { |k, v| "#{k}=#{v}" },
        "Labels" => container_labels,
        "HostConfig" => host_config
      }

      c = Docker::Container.create(container_options)

      Dir.mktmpdir("morph") do |dest|
        copy_config_to_directory(repo_path, dest, false)
        yield(:internalout, "Injecting scraper and running...\n") if block_given?
        # TODO: Combine two operations below into one
        Morph::DockerUtils.insert_contents_of_directory(c, dest, "/app")
        Morph::DockerUtils.insert_file(c, "lib/morph/limit_output.rb",
                                       "/usr/local/bin")
      end

      c.start
      c
    end

    def self.create_morph_network
      begin
        Docker::Network.get(DOCKER_NETWORK)
        exists = true
      rescue Docker::Error::NotFoundError
        exists = false
      end
      return if exists

      Docker::Network.create(
        DOCKER_NETWORK,
        "Options" => {
          "com.docker.network.bridge.name" => DOCKER_BRIDGE,
          "com.docker.network.bridge.enable_icc" => "false"
        },
        "IPAM" => {
          "Config" => [{
            "Subnet" => DOCKER_NETWORK_SUBNET
          }]
        }
      )
    end

    # If since is non-nil only return log lines since the time given. This
    # time is non-inclusive so we shouldn't return the log line with that
    # exact timestamp, just ones after it.
    def self.attach_to_run(container, since = nil)
      params = { stdout: true, stderr: true, follow: true, timestamps: true }
      params[:since] = since.to_f if since
      container.streaming_logs(params) do |s, line|
        timestamp = Time.zone.parse(line[0..29])
        # To convert this ruby time back to the same string format as it
        # originally came in do:
        # timestamp.utc.strftime('%Y-%m-%dT%H:%M:%S.%9NZ')
        c = line[31..-1]
        # We're going to assume (somewhat rashly, I might add) that the
        # console output from the scraper is always encoded as UTF-8.
        # TODO Fix forcing of encoding and do something more intelligent
        # Either figure out the correct encoding or take an educated guess
        # rather than making an assumption
        c.force_encoding("UTF-8")
        c.scrub!
        # There is a chance that we catch a log line that shouldn't
        # be included. So...
        if (since.nil? || timestamp > since) && block_given?
          if s == :stderr && c == "limit_output.rb: Too many lines of output!\n"
            yield timestamp, :internalerr,
              "\n" \
              "Too many lines of output! " \
              "Your scraper will continue uninterrupted. " \
              "There will just be no further output displayed" \
              "\n"
          else
            yield timestamp, s, c
          end
        end
      end
    end

    # This should only get called on a stopped container where all the logs
    # have been collected
    def self.finish(container, files)
      # TODO: Check that container has actually stopped. If not raise an error

      # TODO: Don't call container.json multiple times
      status_code = container.json["State"]["ExitCode"]

      # Make the paths absolute paths for the container
      files = files.map { |f| File.join("/app", f) }

      # Grab the resulting files
      data = Morph::DockerUtils.copy_files(container, files + [time_file])

      time_data_tmp = data.delete(time_file)
      if time_data_tmp
        time_params = Morph::TimeCommand.params_from_string(time_data_tmp.read)
        time_data_tmp.close!
      end

      # Remove /app from the beginning of all paths in data
      data_with_stripped_paths = {}
      data.each do |path, content|
        stripped_path =
          Pathname.new(path).relative_path_from(Pathname.new("/app")).to_s
        data_with_stripped_paths[stripped_path] = content
      end

      # Clean up the container at the last possible moment. This is the
      # signal that we have everything we need
      container.delete(force: true)

      Morph::RunResult.new(status_code, data_with_stripped_paths, time_params)
    end

    # If copy_config is true copies the config file across
    # Otherwise copies the other files across
    def self.copy_config_to_directory(source, dest, copy_config)
      Dir.entries(source).each do |entry|
        next if [".", ".."].include?(entry)

        unless copy_config ^ ALL_CONFIG_FILENAMES.include?(entry)
          FileUtils.copy_entry(File.join(source, entry),
                               File.join(dest, entry))
        end
      end
    end

    # Pulls all the separately tagged buildstep images
    def self.update_docker_images!
      Morph::DockerUtils.pull_docker_image(BUILDSTEP_IMAGE)
    end

    def self.docker_build_command(image, commands, dir)
      # Leave the files in dir untouched
      Dir.mktmpdir("morph") do |dir2|
        Morph::DockerUtils.copy_directory_contents(dir, dir2)
        File.write(File.join(dir2, "Dockerfile"), dockerfile_contents_from_commands(image, commands))

        Morph::DockerUtils.fix_modification_times(dir2)
        Morph::DockerUtils.docker_build_from_dir(
          dir2, read_timeout: 5.minutes
        ) do |c|
          # We don't want to show the standard docker build output
          unless c =~ %r{^Step \d+/\d+ :} || c =~ /^ ---> / ||
                 c =~ /^Removing intermediate container / ||
                 c =~ /^Successfully built /
            yield c
          end
        end
      end
    end

    def self.dockerfile_contents_from_commands(image, commands)
      commands = [commands] unless commands.is_a?(Array)
      lines = ["from #{image.id}"] + commands
      (lines.map { |c| "#{c}\n" }).join
    end

    # And build
    # TODO: Set memory and cpu limits during compile
    def self.compile(image, repo_path, &block)
      Dir.mktmpdir("morph") do |dir|
        FileUtils.mkdir(File.join(dir, "app"))
        copy_config_to_directory(repo_path, File.join(dir, "app"), true)
        docker_build_command(
          image,
          [
            # Insert the configuration part of the application code into the container
            "ADD app /app",
            # TODO: Setting the timeout higher here won't be necessary once we
            # upgrade to a more recent version of herokuish that contains
            # the commit
            # https://github.com/gliderlabs/herokuish/commit/5164f342dfe27537d6fd5425a5121b7ae7925d3c
            # This will probably involve replacing the use of buildstep with
            # using herokuish directly which seems the sensible thing to do now
            "ENV CURL_TIMEOUT 180",
            "ENV NPM_CONFIG_CAFILE /etc/ssl/certs/ca-certificates.crt",
            # Doing this not very nice thing in lieu of figuring out how
            # to set our custom CA cert for all of node
            "ENV NODE_TLS_REJECT_UNAUTHORIZED 0",
            "RUN /bin/herokuish buildpack build"
          ],
          dir, &block
        )
      end
    end
  end
end
