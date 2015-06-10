module Morph
  # High level API for running morph scraper. Handles the setting up of default
  # configuration if things like Gemfiles are not included (for Ruby)
  class Runner
    include Sync::Actions
    attr_accessor :run

    def initialize(run)
      @run = run
    end

    # The main section of the scraper running that is run in the background
    def synch_and_go!
      # If this run belongs to a scraper that has just been deleted then
      # don't do anything
      return if run.scraper.nil?

      Morph::Github.synchronise_repo(run.repo_path, run.git_url)
      go_with_logging
    end

    def go_with_logging
      go do |s, c|
        log(s, c)
        yield s, c if block_given?
      end
    end

    def log(stream, text)
      puts "#{stream}: #{text}" unless Rails.env.test?
      number = run.log_lines.maximum(:number) || 0
      line = run.log_lines.create(stream: stream.to_s, text: text,
                                  number: (number + 1))
      sync_new line, scope: run unless Rails.env.test?
    end

    def go
      # If container already exists we just attach to it
      # Get the container using an interactive connection
      conn_interactive = Docker::Connection.new(
        Docker.url,
        { chunk_size: 1, read_timeout: 4.hours }.merge(Docker.env_options))

      c = container_for_run(conn_interactive)
      if c.nil?
        c = compile_and_start_run do |s, c|
          yield s, c
        end
        lines_to_skip = 0
      else
        # Figure out how many log lines we want to skip
        lines_to_skip = run.log_lines.where("stream = 'stdout' OR stream = 'stderr'").count
      end
      count = 0
      attach_to_run_and_finish(c) do |s, c|
        count += 1
        if count > lines_to_skip
          yield s, c
        end
      end
    end

    def compile_and_start_run
      #puts "Starting...\n"
      run.database.backup
      run.update_attributes(started_at: Time.now,
                            git_revision: run.current_revision_from_repo)
      sync_update run.scraper if run.scraper
      FileUtils.mkdir_p run.data_path
      FileUtils.chmod 0777, run.data_path

      unless run.language && run.language.supported?
        supported_scraper_files =
          Morph::Language.languages_supported.map(&:scraper_filename)
        m = "Can't find scraper code. Expected to find a file called " +
            supported_scraper_files.to_sentence(last_word_connector: ', or ') +
            ' in the root directory'
        yield 'stderr', m
        run.update_attributes(status_code: 999, finished_at: Time.now)
        return
      end

      c = Dir.mktmpdir('morph') do |defaults|
        Morph::Runner.add_config_defaults_to_directory(run.repo_path, defaults)
        Morph::Runner.remove_hidden_directories(defaults)
        Morph::Runner.add_sqlite_db_to_directory(run.data_path, defaults)

        Morph::DockerRunner.compile_and_start_run(
          defaults, run.env_variables, docker_container_labels) do |s, c|
          yield(s, c)
        end
      end

      if c
        # Record ip address of running container
        run.update_attributes(
          ip_address: c.json['NetworkSettings']['IPAddress'])
      end
      c
    end

    def attach_to_run_and_finish(c)
      if c.nil?
        # TODO: Return the status for a compile error
        result = Morph::RunResult.new(255, {}, {})
      else
        result = Morph::DockerRunner.attach_to_run_and_finish(
          c, ['data.sqlite']) do |s, c|
          yield(s, c)
        end
      end

      # Only copy back database if it's there and has something in it
      if result.files && result.files.key?('data.sqlite')
        Morph::Runner.copy_sqlite_db_back(run.data_path, result.files['data.sqlite'])
      end

      # Now collect and save the metrics
      metric = Metric.create(result.time_params) if result.time_params
      metric.update_attributes(run_id: run.id) if metric

      run.update_attributes(status_code: result.status_code, finished_at: Time.now)
      # Update information about what changed in the database
      diffstat = Morph::Database.diffstat_safe(
        run.database.sqlite_db_backup_path, run.database.sqlite_db_path)
      if diffstat
        tables = diffstat[:tables][:counts]
        records = diffstat[:records][:counts]
        run.update_attributes(
          tables_added: tables[:added],
          tables_removed: tables[:removed],
          tables_changed: tables[:changed],
          tables_unchanged: tables[:unchanged],
          records_added: records[:added],
          records_removed: records[:removed],
          records_changed: records[:changed],
          records_unchanged: records[:unchanged]
        )
      end
      Morph::Database.tidy_data_path(run.data_path)
      if run.scraper
        run.scraper.update_sqlite_db_size
        run.scraper.reindex
        run.scraper.reload
        sync_update run.scraper
      end
    end

    # Note that cleanup is automatically done by the process on the
    # background queue attached to the container. When the scraper process is
    # killed here, the attach block finishes and the container cleanup is done
    # as if the scraper had stopped on its own
    # TODO: Make this stop the compile stage
    def stop!
      container = Morph::DockerUtils.find_container_with_label(
        Morph::Runner.run_label_key, run_label_value)
      if container
        container.kill
      else
        # If there is no container then there can't be a watch process to
        # do update the run so we must do it here
        run.update_attributes(status_code: 255, finished_at: Time.now)
        # TODO: Do a sync_update?
      end
    end

    def self.add_sqlite_db_to_directory(data_path, dir)
      # Copy across the current sqlite database as well
      if File.exist?(File.join(data_path, 'data.sqlite'))
        # TODO: Ensure that there isn't anything else writing to the db
        # while we make a copy of it. There's the backup API. Use that?
        FileUtils.cp(File.join(data_path, 'data.sqlite'), dir)
      else
        # Copy across a zero-sized file which will overwrite the symbolic
        # link on the container
        FileUtils.touch(File.join(dir, 'data.sqlite'))
      end
    end

    def self.copy_sqlite_db_back(data_path, sqlite_data)
      # Only overwrite the sqlite database if the container has one
      if sqlite_data
        # First write to a temporary file with the new sqlite data
        File.open(File.join(data_path, 'data.sqlite.new'), 'wb') do |f|
          f << sqlite_data
        end
        # Then, rename the file to the "live" file overwriting the old data
        # This should happen atomically
        File.rename(File.join(data_path, 'data.sqlite.new'),
                    File.join(data_path, 'data.sqlite'))
      end
    end

    def self.add_config_defaults_to_directory(source, dest)
      Morph::DockerUtils.copy_directory_contents(source, dest)
      # We don't need to check that the language is recognised because
      # the compiler is never called if the language isn't valid
      language = Morph::Language.language(dest)

      language.default_files_to_insert.each do |files|
        if files.all? { |file| !File.exist?(File.join(dest, file)) }
          files.each do |file|
            FileUtils.cp(language.default_config_file_path(file),
                         File.join(dest, file))
          end
        end
      end

      # Special behaviour for Procfile. We don't allow the user to override this
      FileUtils.cp(language.default_config_file_path('Procfile'),
                   File.join(dest, 'Procfile'))
    end

    # Remove directories starting with "."
    # TODO: Make it just remove the .git directory in the root and not other
    # hidden directories which people might find useful
    def self.remove_hidden_directories(directory)
      Find.find(directory) do |path|
        if FileTest.directory?(path) && File.basename(path)[0] == ?.
          FileUtils.rm_rf(path)
        end
      end
    end

    def self.run_label_key
      'io.morph.run'
    end

    def run_label_value
      run.id.to_s
    end

    # How to label the container for the actually running scraper
    def docker_container_labels
      # Everything needs to be a string
      labels = { Morph::Runner.run_label_key => run_label_value }
      labels['io.morph.scraper'] = run.scraper.full_name if run.scraper
      labels
    end

    def container_for_run(connection = Docker.connection)
      Morph::DockerUtils.find_container_with_label(
        Morph::Runner.run_label_key, run_label_value, connection)
    end

    def self.run_id_for_container(container)
      value = Morph::DockerUtils.label_value(container, run_label_key)
      value.to_i if value
    end

    # Given a run return the associated run object
    def self.run_for_container(container)
      run_id = run_id_for_container(container)
      Run.find(run_id) if run_id
    end
  end
end
