# typed: strict
# frozen_string_literal: true

module Morph
  # High level API for running morph scraper. Handles the setting up of default
  # configuration if things like Gemfiles are not included (for Ruby)
  class Runner
    extend T::Sig

    include RenderSync::Actions
    sig { returns(Run) }
    attr_accessor :run

    sig { params(run: Run).void }
    def initialize(run)
      @run = run
    end

    # TODO: Move this to a configuration somewhere
    sig { returns(Integer) }
    def self.default_max_lines
      10_000
    end

    sig { returns(Integer) }
    def self.total_slots
      SiteSetting.maximum_concurrent_scrapers
    end

    # This includes stopped containers too
    sig { returns(Integer) }
    def self.used_slots
      Morph::DockerUtils.find_all_containers_with_label(run_label_key).count
    end

    sig { returns(Integer) }
    def self.available_slots
      total_slots - used_slots
    end

    # The main section of the scraper running that is run in the background
    sig { params(block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).void }
    def synch_and_go_with_logging!(&block)
      synch_and_go! do |timestamp, s, c|
        log(timestamp, s, c, &block)
      end
    end

    sig { params(max_lines: Integer, block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).void }
    def go_with_logging(max_lines = Runner.default_max_lines, &block)
      go(max_lines) do |timestamp, s, c|
        log(timestamp, s, c, &block)
      end
    end

    sig { params(timestamp: T.nilable(Time), stream: Symbol, text: String, block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).void }
    def log(timestamp, stream, text, &block)
      Rails.logger.info "#{stream}: #{text}" if Rails.env.development?
      # Not using create on association to try to avoid memory bloat
      # Truncate text so that it fits in the database
      # Note that mysql TEXT is limited to 65535 bytes so we have to be
      # particularly careful with unicode.
      line = LogLine.create!(run: run, timestamp: timestamp, stream: stream.to_s, text: text.mb_chars.limit(65535).to_s)
      sync_new line, scope: run unless Rails.env.test?
      block.call timestamp, stream, text if block_given?
    end

    sig { params(text: String, status_code: Integer, block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).void }
    def error(text:, status_code:, &block)
      block.call(nil, :internalerr, text) if block_given?
      run.update(status_code: status_code, finished_at: Time.zone.now)
      sync_update run.scraper if run.scraper
    end

    sig { params(block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).void }
    def synch_and_go!(&block)
      scraper = run.scraper
      # If this run belongs to a scraper that has just been deleted
      # or if the run has already been marked as finished then
      # don't do anything
      return if scraper.nil? || run.finished?

      # TODO: Indicate that scraper is running before we do the synching
      error = SynchroniseRepoService.call(scraper)
      case error
      when nil
        nil
      when Morph::GithubAppInstallation::NoAppInstallationForOwner
        error(
          status_code: 999,
          text: "Please install the Morph Github App on #{T.must(scraper.owner).nickname} so that Morph can access this repository on GitHub. Please go to #{T.must(scraper.owner).app_install_url}",
          &block
        )
        return
      when Morph::GithubAppInstallation::AppInstallationNoAccessToRepo
        error(
          status_code: 999,
          text: "The Morph Github App installed on #{T.must(scraper.owner).nickname} needs access to the repository #{scraper.name}. Please go to #{T.must(scraper.owner).app_install_url}",
          &block
        )
        return
      when Morph::GithubAppInstallation::SynchroniseRepoError, Morph::GithubAppInstallation::NoAccessToRepo
        error(text: "There was a problem getting the latest scraper code from GitHub", status_code: 999, &block)
        return
      when SynchroniseRepoService::RepoNeedsToBePublic
        error(
          status_code: 999,
          text: "The repository #{scraper.full_name} needs to be made public",
          &block
        )
        return
      when SynchroniseRepoService::RepoNeedsToBePrivate
        error(
          status_code: 999,
          text: "The repository #{scraper.full_name} needs to be made private",
          &block
        )
        return
      else
        T.absurd(error)
      end

      go(Runner.default_max_lines, &block)
    end

    sig { params(max_lines: Integer, block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).void }
    def go(max_lines = Runner.default_max_lines, &block)
      # If container already exists we just attach to it
      c = container_for_run
      if c.nil?
        c = compile_and_start_run(max_lines, &block)
        since = nil
      else
        # The timestamp of the last log line we've already captured
        since = run.log_lines.maximum(:timestamp)
        # We add a microsecond to compensate for rounding error as
        # part of the time being stored in the database. The true time
        # gets truncated to the lower microsecond. So, likely the true
        # time happens *after* the recorded time. So, we add a microsecond
        # to compensate for this and ensure that the "since" time occurs
        # slightly after the true time.
        since += 1e-6 if since
      end
      attach_to_run_and_finish(c, since, &block)
    end

    # TODO: Could we get sensible timestamps out at this stage too?
    # Right now we're just returning nil for the timestamps here
    sig { params(max_lines: Integer, block: T.nilable(T.proc.params(timestamp: T.nilable(Time), stream: Symbol, text: String).void)).returns(T.nilable(Docker::Container)) }
    def compile_and_start_run(max_lines = Runner.default_max_lines, &block)
      # puts "Starting...\n"
      run.database.backup
      # If the run is not part of a scraper (e.g. through the api) then there won't be a git repository
      git_revision = Morph::Github.current_revision_from_repo(run.repo_path) unless run.scraper.nil?
      run.update(started_at: Time.zone.now, git_revision: git_revision)
      sync_update run.scraper if run.scraper
      FileUtils.mkdir_p run.data_path
      FileUtils.chmod 0o777, run.data_path

      unless run.language&.supported?
        supported_scraper_files =
          Morph::Language.languages_supported.map(&:scraper_filename)
        supported_scraper_files_as_text = supported_scraper_files.to_sentence(last_word_connector: ", or ")
        error(text: "Can't find scraper code. Expected to find a file called #{supported_scraper_files_as_text} in the root directory", status_code: 999, &block)
        return
      end

      platform = run.scraper&.platform
      unless platform.nil? || Morph::DockerRunner::PLATFORMS.include?(platform)
        error(text: "Platform set to an invalid value. Valid values are #{Morph::DockerRunner::PLATFORMS.join(', ')}.", status_code: 999, &block)
        return
      end

      c = Dir.mktmpdir("morph") do |defaults|
        Morph::Runner.add_config_defaults_to_directory(run.repo_path, defaults)
        Morph::Runner.remove_hidden_directories(defaults)
        Morph::Runner.add_sqlite_db_to_directory(run.data_path, defaults)

        scraper = run.scraper
        memory_mb = scraper&.memory_mb
        Morph::DockerRunner.compile_and_start_run(
          repo_path: defaults,
          env_variables: run.env_variables,
          container_labels: docker_container_labels,
          max_lines: max_lines,
          platform: platform,
          # We're disabling the proxy for all scrapers
          disable_proxy: true,
          memory: (memory_mb * 1024 * 1024 if memory_mb), &block
        )
      end

      if c
        # Record ip address of running container
        ip_address = Morph::DockerUtils.ip_address_of_container(c)

        # Getting the image that this container was built from
        # Doing it in this way so that it is backwards compatible with
        # a short version of the id without "sha256:" at the beginning
        docker_image = c.json["Image"].split(":")[1][0..11]

        run.update(ip_address: ip_address, docker_image: docker_image)
      end
      c
    end

    sig { params(container: T.nilable(Docker::Container), since: T.nilable(Time), block: T.nilable(T.proc.params(timestamp: Time, stream: Symbol, text: String).void)).void }
    def attach_to_run_and_finish(container, since, &block)
      if container.nil?
        # TODO: Return the status for a compile error
        result = Morph::RunResult.new(255, {}, {})
      else
        Morph::DockerRunner.attach_to_run(container, since, &block)
        result = Morph::DockerRunner.finish(container, ["data.sqlite"])
      end

      status_code = result.status_code

      db_tempfile = result.files["data.sqlite"]
      # Only copy back database if it's there and has something in it
      if db_tempfile
        Morph::Runner.copy_sqlite_db_back(run.data_path, T.must(db_tempfile.path))
        db_tempfile.close!
      # Only show the error below if the scraper thinks it finished without problems
      elsif status_code.zero?
        m = <<~ERROR
          Scraper didn't create an SQLite database in your current working directory called
          data.sqlite. If you've just created your first scraper and not edited the code yet
          this is to be expected.

          To fix this make your scraper write to an SQLite database at data.sqlite.
        ERROR
        block.call Time.zone.now, :internalerr, m if block_given?
        status_code = 998
      end

      # Now collect and save the metrics
      T.must(run.metric).update(result.time_params) if result.time_params

      # Because SqliteDiff will actually create sqlite databases if they
      # don't exist we don't actually want that if there isn't actually
      # a database because it causes some very confusing behaviour
      if File.exist?(run.database.sqlite_db_path)
        # Update information about what changed in the database
        diffstat = Morph::SqliteDiff.diffstat_safe(
          run.database.sqlite_db_backup_path, run.database.sqlite_db_path
        )
        if diffstat
          tables = diffstat.tables.counts
          records = diffstat.records
          run.update(
            tables_added: tables.added,
            tables_removed: tables.removed,
            tables_changed: tables.changed,
            tables_unchanged: tables.unchanged,
            records_added: records.added,
            records_removed: records.removed,
            records_changed: records.changed,
            records_unchanged: records.unchanged
          )
        end
      end

      run.update(status_code: status_code, finished_at: Time.zone.now)

      return unless run.scraper

      run.finished!
      sync_update run.scraper
    end

    # Note that cleanup is automatically done by the process on the
    # background queue attached to the container. When the scraper process is
    # killed here, the attach block finishes and the container cleanup is done
    # as if the scraper had stopped on its own
    # TODO: Make this stop the compile stage
    sig { void }
    def stop!
      container = container_for_run
      if container
        container.kill
      else
        # If there is no container then there can't be a watch process to
        # do update the run so we must do it here
        run.update(status_code: 255, finished_at: Time.zone.now)
        # TODO: Do a sync_update?
      end
    end

    sig { params(data_path: String, dir: String).void }
    def self.add_sqlite_db_to_directory(data_path, dir)
      return unless File.exist?(File.join(data_path, "data.sqlite"))

      # Copy across the current sqlite database as well
      # TODO: Ensure that there isn't anything else writing to the db
      # while we make a copy of it. There's the backup API. Use that?
      FileUtils.cp(File.join(data_path, "data.sqlite"), dir)
    end

    sig { params(data_path: String, sqlite_file_path: String).void }
    def self.copy_sqlite_db_back(data_path, sqlite_file_path)
      # First write to a temporary file with the new sqlite data
      # Copying across just in case temp directory and data_path directory
      # not on the same filesystem (which would stop atomic rename from working)
      FileUtils.cp(sqlite_file_path, File.join(data_path, "data.sqlite.new"))
      # Then, rename the file to the "live" file overwriting the old data
      # This should happen atomically
      File.rename(File.join(data_path, "data.sqlite.new"),
                  File.join(data_path, "data.sqlite"))
    end

    sig { params(source: String, dest: String).void }
    def self.add_config_defaults_to_directory(source, dest)
      Morph::DockerUtils.copy_directory_contents(source, dest)
      # We don't need to check that the language is recognised because
      # the compiler is never called if the language isn't valid
      language = T.must(Morph::Language.language(dest))

      language.default_files_to_insert.each do |files|
        next unless files.all? { |file| !File.exist?(File.join(dest, file)) }

        files.each do |file|
          FileUtils.cp(language.default_config_file_path(file),
                       File.join(dest, file))
        end
      end

      # Special behaviour for Procfile. We don't allow the user to override this
      File.open(File.join(dest, "Procfile"), "w") { |f| f << language.procfile }
    end

    # Remove directories starting with "."
    # TODO: Make it just remove the .git directory in the root and not other
    # hidden directories which people might find useful
    sig { params(directory: String).void }
    def self.remove_hidden_directories(directory)
      Find.find(directory) do |path|
        FileUtils.rm_rf(path) if FileTest.directory?(path) && File.basename(path)[0] == "."
      end
    end

    sig { returns(String) }
    def self.run_label_key
      "io.morph.run"
    end

    sig { returns(String) }
    def run_label_value
      run.id.to_s
    end

    # How to label the container for the actually running scraper
    sig { returns(T::Hash[String, String]) }
    def docker_container_labels
      # Everything needs to be a string
      labels = { Morph::Runner.run_label_key => run_label_value }
      scraper = run.scraper
      labels["io.morph.scraper"] = scraper.full_name if scraper
      labels
    end

    sig { returns(T.nilable(Docker::Container)) }
    def container_for_run
      Morph::DockerUtils.find_container_with_label(
        Morph::Runner.run_label_key, run_label_value
      )
    end

    sig { params(container: Docker::Container).returns(T.nilable(Integer)) }
    def self.run_id_for_container(container)
      value = Morph::DockerUtils.label_value(container, run_label_key)
      value&.to_i
    end

    # Given a run return the associated run object
    # If run has been deleted for this container then also return nil
    sig { params(container: Docker::Container).returns(T.nilable(Run)) }
    def self.run_for_container(container)
      run_id = run_id_for_container(container)
      Run.find_by(id: run_id) if run_id
    end
  end
end
