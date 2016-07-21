# To define Sidekiq::Shutdown
require 'sidekiq/cli'

module Morph
  # More low-level API for running scrapers. Does not do much of the magic
  # and is less opinionated than the higher-level API in Morph::Runner
  class DockerRunner
    ALL_CONFIG_FILENAMES = [
      'Procfile',
      'Gemfile', 'Gemfile.lock',
      'requirements.txt', 'runtime.txt',
      'composer.json', 'composer.lock',
      'app.psgi', 'cpanfile',
      'package.json'
    ]
    BUILDSTEP_IMAGE = 'openaustralia/buildstep'

    def self.time_file
      '/app/time.output'
    end

    # Memory limit applied to running container (in bytes)
    def self.memory_limit
      512 * 1024 * 1024
    end

    def self.compile_and_start_run(
      repo_path, env_variables, container_labels)
      i = Morph::DockerUtils.get_or_pull_image(BUILDSTEP_IMAGE) do |c|
        yield(:internalout, c)
      end
      # Insert the configuration part of the application code into the container
      i2 = Dir.mktmpdir('morph') do |dest|
        copy_config_to_directory(repo_path, dest, true)
        yield(:internalout, "Injecting configuration and compiling...\n")
        inject_files(i, dest)
      end
      i3 = compile(i2) do |c|
        yield(:internalout, c)
      end
      # If something went wrong during the compile and it couldn't finish
      return [nil, nil] if i3.nil?

      # Insert the actual code (and database) into the container
      i4 = Dir.mktmpdir('morph') do |dest|
        copy_config_to_directory(repo_path, dest, false)
        yield(:internalout, "Injecting scraper and running...\n")
        inject_files2(i3, dest)
      end

      command = Morph::TimeCommand.command(['/start', 'scraper'], time_file)

      # TODO: Also copy back time output file and the sqlite journal file
      # The sqlite journal file won't be present most of the time

      container_options = {
        'Cmd' => command,
        'Image' => i4.id,
        # See explanation in https://github.com/openaustralia/morph/issues/242
        'CpuShares' => 307,
        'Memory' => memory_limit,
        'Env' =>
          {
            'REQUESTS_CA_BUNDLE' => '/etc/ssl/certs/ca-certificates.crt'
          }.merge(env_variables).map { |k, v| "#{k}=#{v}" },
        'Labels' => container_labels
      }

      c = Docker::Container.create(container_options)
      c.start
      [c, i3]
    end

    def self.normalise_log_content(c)
      # We're going to assume (somewhat rashly, I might add) that the
      # console output from the scraper is always encoded as UTF-8.
      c.force_encoding('UTF-8')
      c.scrub!
      # There are times when multiple lines are returned and this does
      # not always happen consistently. So, for simplicity and consistency
      # we will split multiple lines up
      line_buffer = Morph::LineBuffer.new
      line_buffer << c

      result = line_buffer.extract
      # Anything left over
      f = line_buffer.finish
      result << f if f.length > 0
      result
    end

    def self.attach_to_run_and_finish(container, files)
      if container.json['State']['Running']
        # TODO: We need to gracefully handle Docker::Error::TimeoutError
        # This should involve throwing a specific exception (something like
        # Morph::IntentionalRequeue) that says "requeue this" and then we
        # need to make sure that the requeud job reattaches to the existing
        # container. It should be able to handle the container still running
        # as well as having stopped. We can also shorten the read timeout as
        # it doesn't really have anything to do with how long scrapers are
        # allowed to run. It's just the time between reads of the log before
        # the attach read times out. So, a scraper that outputs stuff to
        # standard out regularly can run a lot longer than one that doesn't.

        # We want output to be streamed here in real time so we need to
        # get the container again with an "interactive" connection.
        interactive_container =
          Morph::DockerUtils.container_with_interactive_connection(
            container, read_timeout: 5.minutes)

        begin
          interactive_container.attach(logs: true) do |s, c|
            normalise_log_content(c).each do |content|
              yield s, content
            end
          end
        rescue Excon::Errors::SocketError
          # FIXME: This allows kill_due_to_excessive_log_lines to do its job
          # but there's got to be a better way
          true
        end
      else
        # Just grab all the logs
        container.streaming_logs(stdout: true, stderr: true) do |s, c|
          normalise_log_content(c).each do |content|
            yield s, content
          end
        end
      end

      finish(container, files)
    end

    def self.finish(container, files)
      # TODO: Don't call container.json multiple times
      status_code = container.json['State']['ExitCode']
      # Wait until container has definitely stopped
      container.wait

      # Make the paths absolute paths for the container
      files = files.map { |f| File.join('/app', f) }

      # Grab the resulting files
      data = Morph::DockerUtils.copy_files(container, files + [time_file])

      # Before we delete the container get the image it was made from
      i4 = Docker::Image.get(container.json['Image'])

      # Clean up after ourselves
      container.delete

      time_data = data.delete(time_file)
      if time_data
        time_params = Morph::TimeCommand.params_from_string(time_data)
      end

      # Remove /app from the beginning of all paths in data
      data_with_stripped_paths = {}
      data.each do |path, content|
        stripped_path =
          Pathname.new(path).relative_path_from(Pathname.new('/app')).to_s
        data_with_stripped_paths[stripped_path] = content
      end

      # There's a potential race condition here where we are trying to delete
      # something that might be used elsewhere. Do the most crude thing and
      # just ignore any errors that deleting might throw up.
      # TODO: We wouldn't need to clean up the image with the scraper code if
      # we injected the scraper code via stdin when we attach to the container

      # There are actually two layers to clean up
      parent = Morph::DockerUtils.parent_image(i4)
      Morph::DockerUtils.remove_single_docker_image(i4)
      Morph::DockerUtils.remove_single_docker_image(parent)

      Morph::RunResult.new(status_code, data_with_stripped_paths, time_params)
    end

    # If copy_config is true copies the config file across
    # Otherwise copies the other files across
    def self.copy_config_to_directory(source, dest, copy_config)
      Dir.entries(source).each do |entry|
        next if entry == '.' || entry == '..'

        unless copy_config ^ ALL_CONFIG_FILENAMES.include?(entry)
          FileUtils.copy_entry(File.join(source, entry),
                               File.join(dest, entry))
        end
      end
    end

    def self.update_docker_image!
      Morph::DockerUtils.pull_docker_image(BUILDSTEP_IMAGE)
    end

    private

    def self.docker_build_command(image, commands, dir)
      # Leave the files in dir untouched
      Dir.mktmpdir('morph') do |dir2|
        Morph::DockerUtils.copy_directory_contents(dir, dir2)
        File.open(File.join(dir2, 'Dockerfile'), 'w') do |f|
          f.write dockerfile_contents_from_commands(image, commands)
        end

        Morph::DockerUtils.fix_modification_times(dir2)
        Morph::DockerUtils.docker_build_from_dir(
          dir2, { read_timeout: 5.minutes }) do |c|
          yield c
        end
      end
    end

    def self.dockerfile_contents_from_commands(image, commands)
      commands = [commands] unless commands.is_a?(Array)
      "from #{image.id}\n" + commands.map { |c| c + "\n" }.join
    end

    # Inject all files in the given directory into the /app directory in the
    # image and return a new image
    def self.inject_files(image, dest)
      Dir.mktmpdir('morph') do |dir|
        FileUtils.mkdir(File.join(dir, 'app'))
        Morph::DockerUtils.copy_directory_contents(dest, File.join(dir, 'app'))
        docker_build_command(image, ['ADD app /app'], dir) do
          # Note that we're not sending the output of this to the console
          # because it is relatively short running and is otherwise confusing
        end
      end
    end

    def self.inject_files2(image, dest)
      Dir.mktmpdir('morph') do |dir|
        Morph::DockerUtils.copy_directory_contents(dest, File.join(dir, 'app'))
        docker_build_command(
          image,
          ['ADD app /app', 'RUN chown -R scraper:scraper /app'],
          dir) do
          # Note that we're not sending the output of this to the console
          # because it is relatively short running and is otherwise confusing
        end
      end
    end

    # And build
    # TODO: Set memory and cpu limits during compile
    def self.compile(image)
      Dir.mktmpdir('morph') do |dir|
        docker_build_command(
          image,
          [
            'ENV CURL_TIMEOUT 180',
            'ENV NPM_CONFIG_CAFILE /etc/ssl/certs/ca-certificates.crt',
            # Doing this not very nice thing in lieu of figuring out how
            # to set our custom CA cert for all of node
            'ENV NODE_TLS_REJECT_UNAUTHORIZED 0',
            'RUN /build/builder'
          ],
          dir) do |c|
          # We don't want to show the standard docker build output
          unless c =~ /^Step \d+ :/ || c =~ /^ ---> / ||
                 c =~ /^Removing intermediate container / ||
                 c =~ /^Successfully built /
            yield c
          end
        end
      end
    end
  end
end
