# typed: false
# frozen_string_literal: true

require "spec_helper"
# To define Sidekiq::Shutdown
require "sidekiq/cli"

describe Morph::Runner do
  describe "slot management" do
    it "returns total slots from SiteSetting" do
      allow(SiteSetting).to receive(:maximum_concurrent_scrapers).and_return(5)
      expect(described_class.total_slots).to eq(5)
    end

    it "calculates used and available slots" do
      allow(Morph::DockerUtils).to receive(:find_all_containers_with_label).and_return([instance_double(Docker::Container), instance_double(Docker::Container)])
      allow(described_class).to receive(:total_slots).and_return(10)
      expect(described_class.used_slots).to eq(2)
      expect(described_class.available_slots).to eq(8)
    end
  end

  describe ".log" do
    # TODO: Hmmm.. When do the callbacks get reenabled?
    before { Searchkick.disable_callbacks }

    let(:owner) { User.create(nickname: "mlandauer") }
    let(:run) { Run.create(owner: owner) }
    let(:runner) { described_class.new(run) }

    it "logs console output to the run" do
      runner.log(Time.zone.now, :stdout, "This is a test")
      expect(run.log_lines.count).to eq 1
      expect(run.log_lines.first.stream).to eq "stdout"
      expect(run.log_lines.first.text).to eq "This is a test"
    end

    it "truncates a very long entry" do
      runner.log(Time.zone.now, :stdout, "☃" * 65540)
      expect(run.log_lines.first.text.bytesize).to eq 65535
    end
  end

  describe "#synch_and_go!" do
    let(:run) { Run.create(owner: User.create(nickname: "testuser")) }
    let(:runner) { described_class.new(run) }

    it "returns early if scraper is nil" do
      run.update(scraper: nil)
      allow(SynchroniseRepoService).to receive(:call)
      runner.synch_and_go!
      expect(SynchroniseRepoService).not_to have_received(:call)
    end

    it "returns early if run is finished" do
      run.update(finished_at: Time.zone.now, status_code: 0)
      allow(SynchroniseRepoService).to receive(:call)
      runner.synch_and_go!
      expect(SynchroniseRepoService).not_to have_received(:call)
    end

    # FIXME: Fix spec causes code to unexpectedly reach T.absurd(error)
    # it "handles NoAppInstallationForOwner error" do
    #   scraper = create(:scraper, name: "test-scraper", owner: run.owner)
    #   run.update(scraper: scraper)
    #   allow(SynchroniseRepoService).to receive(:call).and_return(Morph::GithubAppInstallation::NoAppInstallationForOwner)
    #   allow(runner).to receive(:error)
    #
    #   runner.synch_and_go!
    #   expect(runner).to have_received(:error).with(hash_including(status_code: 999, text: /Please install the Morph Github App/))
    # end

    # FIXME: Fix spec causes code to unexpectedly reach T.absurd(error)
    # it "handles AppInstallationNoAccessToRepo error" do
    #   scraper = create(:scraper, name: "test-scraper", owner: run.owner)
    #   run.update(scraper: scraper)
    #   allow(SynchroniseRepoService).to receive(:call).and_return(Morph::GithubAppInstallation::AppInstallationNoAccessToRepo)
    #   allow(runner).to receive(:error)
    #
    #   runner.synch_and_go!
    #   expect(runner).to have_received(:error).with(hash_including(status_code: 999, text: /needs access to the repository/))
    # end

    # FIXME: Fix spec causes code to unexpectedly reach T.absurd(error)
    # it "handles RepoNeedsToBePublic error" do
    #   scraper = create(:scraper, name: "test-scraper", owner: run.owner)
    #   run.update(scraper: scraper)
    #   allow(SynchroniseRepoService).to receive(:call).and_return(SynchroniseRepoService::RepoNeedsToBePublic)
    #   allow(runner).to receive(:error)
    #
    #   runner.synch_and_go!
    #   expect(runner).to have_received(:error).with(hash_including(status_code: 999, text: /needs to be made public/))
    # end

    # FIXME: Fix spec causes code to unexpectedly reach T.absurd(error)
    # it "handles RepoNeedsToBePrivate error" do
    #   scraper = create(:scraper, name: "test-scraper", owner: run.owner)
    #   run.update(scraper: scraper)
    #   allow(SynchroniseRepoService).to receive(:call).and_return(SynchroniseRepoService::RepoNeedsToBePrivate)
    #   allow(runner).to receive(:error)
    #
    #   runner.synch_and_go!
    #   expect(runner).to have_received(:error).with(hash_including(status_code: 999, text: /needs to be made private/))
    # end
  end

  describe ".go", docker: true do
    it "runs without an associated scraper" do
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      run.database.clear
      expect(run.database.no_rows).to eq 0
      fill_scraper_for_run("save_to_database", run)
      described_class.new(run).go
      run.reload
      expect(run.status_code).to eq 0
      expect(run.database.no_rows).to eq 1
    end

    it "magicallies handle a sidekiq queue restart", slow: true do
      # 1.9 seconds
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      fill_scraper_for_run("stream_output", run)
      logs = []

      runner = described_class.new(run)
      running_count = Morph::DockerUtils.running_containers.count
      expect do
        runner.go_with_logging do |_timestamp, s, c|
          # Only record stdout so we can handle different results as a result
          # of caching of the compile stage
          logs << c if s == :stdout

          raise Sidekiq::Shutdown if c.include? "2..."
        end
      end.to raise_error(Sidekiq::Shutdown)
      run.reload
      expect(run).to be_running
      # We expect the container to still be running
      expect(Morph::DockerUtils.running_containers.count)
        .to eq(running_count + 1)
      expect(run.database.first_ten_rows).to eq []

      # Now, we simulate the queue restarting the job
      started_at = run.started_at
      runner.go do |_timestamp, _stream, text|
        logs << text
      end
      expect(logs.join).to eq %W[Started!\n 1...\n 2...\n 3...\n 4...\n 5...\n 6...\n 7...\n 8...\n 9...\n 10...\n Finished!\n].join
      run.reload
      # The start time shouldn't have changed
      expect(run.started_at).to eq started_at
      expect(run.database.first_ten_rows).to eq [
        { "state" => "started" }, { "state" => "finished" }
      ]
    end

    it "handles restarting from a stopped container", slow: true do
      # 2.9 seconds
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      fill_scraper_for_run("stream_output", run)
      logs = []

      runner = described_class.new(run)
      running_count = Morph::DockerUtils.running_containers.count
      expect do
        runner.go do |_timestamp, s, c|
          logs << c if s == :stdout

          raise Sidekiq::Shutdown if c.include? "2..."
        end
      end.to raise_error(Sidekiq::Shutdown)
      expect(logs.join).to eq %W[Started!\n 1...\n 2...\n].join
      run.reload
      expect(run).to be_running
      # We expect the container to still be running
      expect(Morph::DockerUtils.running_containers.count)
        .to eq(running_count + 1)
      expect(run.database.first_ten_rows).to eq []

      # Wait until container is stopped
      sleep 2

      # Now, we simulate the queue restarting the job
      started_at = run.started_at
      logs = []
      runner.go do |_timestamp, _stream, text|
        logs << text
        # puts c
      end
      # TODO: Really we only want to get newer logs
      expect(logs.join).to eq [
        "Started!\n",
        "1...\n",
        "2...\n",
        "3...\n",
        "4...\n",
        "5...\n",
        "6...\n",
        "7...\n",
        "8...\n",
        "9...\n",
        "10...\n",
        "Finished!\n"
      ].join
      run.reload
      # The start time shouldn't have changed
      expect(run.started_at).to eq started_at
      expect(run.database.first_ten_rows).to eq [
        { "state" => "started" }, { "state" => "finished" }
      ]
    end

    it "is able to limit the number of lines of output", slow: true do
      # 1.9 seconds
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      fill_scraper_for_run("stream_output", run)
      logs = []
      runner = described_class.new(run)
      runner.go_with_logging(5) do |_timestamp, s, c|
        # Only record stdout so we can handle different results as a result
        # of caching of the compile stage
        logs << [s, c]
      end
      # TODO: Also test the creation of the correct number of log line records
      expect(logs[-6..-1]).to eq [
        [:stdout, "Started!\n"],
        [:stdout, "1...\n"],
        [:stdout, "2...\n"],
        [:stdout, "3...\n"],
        [:stdout, "4...\n"],
        [:internalerr, "\nToo many lines of output! Your scraper will continue uninterrupted. There will just be no further output displayed\n"]
      ]
    end

    # Have to disable the test below for the time being because we can't
    # hardcode the morph subnet anymore after the update of the morph server
    # to Xenial
    # it 'should record the container ip address in the run' do
    #   owner = User.create(nickname: 'mlandauer')
    #   run = Run.create(owner: owner)
    #   FileUtils.rm_rf(run.data_path)
    #   FileUtils.rm_rf(run.repo_path)
    #   fill_scraper_for_run('save_to_database', run)
    #   runner = Morph::Runner.new(run)
    #   runner.go_with_logging {}
    #   run.reload
    #   subnet = run.ip_address.split(".")[0..1].join(".")
    #   expect(subnet).to eq "192.168"
    # end

    it "is able to correctly limit the number of lines even after a restart", slow: true do
      # 1.9 seconds
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      fill_scraper_for_run("stream_output", run)
      logs = []
      runner = described_class.new(run)
      expect do
        runner.go_with_logging(5) do |_timestamp, s, c|
          # Only record stdout so we can handle different results as a result
          # of caching of the compile stage
          logs << [s, c]

          raise Sidekiq::Shutdown if c.include? "2..."
        end
      end.to raise_error Sidekiq::Shutdown
      expect(logs[-3..-1]).to eq [
        [:stdout, "Started!\n"],
        [:stdout, "1...\n"],
        [:stdout, "2...\n"]
      ]
      runner.go_with_logging(5) do |_timestamp, s, c|
        logs << [s, c]
      end
      expect(logs[-6..-1]).to eq [
        [:stdout, "Started!\n"],
        [:stdout, "1...\n"],
        [:stdout, "2...\n"],
        [:stdout, "3...\n"],
        [:stdout, "4...\n"],
        [:internalerr, "\nToo many lines of output! Your scraper will continue uninterrupted. There will just be no further output displayed\n"]
      ]
    end

    it "handles missing database file with status code zero" do
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      fill_scraper_for_run("save_to_database", run) # Just to pass compile

      # Mock DockerRunner to return success but no file
      result = Morph::RunResult.new(0, {}, {})
      allow(Morph::DockerRunner).to receive(:attach_to_run)
      allow(Morph::DockerRunner).to receive(:finish).and_return(result)

      logs = []
      described_class.new(run).go { |_t, s, c| logs << [s, c] }

      expect(run.reload.status_code).to eq 998
      expect(logs.last[0]).to eq :internalerr
      expect(logs.last[1]).to include("Scraper didn't create an SQLite database")
    end

    it "updates database diff information if database exists", faye: true do
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      scraper = create(:scraper, name: "test", owner: owner)
      run.update(scraper: scraper)

      # Ensure the reop exists
      FileUtils.mkdir_p(run.repo_path)
      FileUtils.cp_r(Rails.root.join("default_files/ruby/template/."), run.repo_path)
      Dir.chdir(run.repo_path) do
        system "git init -q ."
        system "git add ."
        system "git commit -q -m 'Initial commit'"
      end
      # Ensure the database paths exist
      FileUtils.mkdir_p(File.dirname(run.database.sqlite_db_path))
      FileUtils.touch(run.database.sqlite_db_path)
      FileUtils.touch(run.database.sqlite_db_backup_path)

      # rubocop:disable RSpec/VerifiedDoubles
      # Using unverified doubles here because these are dynamic objects with simple attribute access
      # that don't have a well-defined class structure in the Morph::SqliteDiff module
      diffstat = instance_double(Morph::SqliteDiff::DiffStruct,
                                 tables: double(counts: double(added: 1, removed: 0, changed: 2, unchanged: 5)),
                                 records: double(added: 10, removed: 5, changed: 3, unchanged: 100))
      # rubocop:enable RSpec/VerifiedDoubles
      allow(Morph::SqliteDiff).to receive(:diffstat_safe).and_return(diffstat)

      # Mock result to skip actual docker finish details
      time_params = { wall_time: 45.67, utime: 1.23, stime: 0.54 }
      result = Morph::RunResult.new(0, { "data.sqlite" => Tempfile.new("data") }, time_params)
      allow(Morph::DockerRunner).to receive(:attach_to_run)
      allow(Morph::DockerRunner).to receive(:finish).and_return(result)
      allow(described_class).to receive(:copy_sqlite_db_back)

      # stub out external calls
      instance = described_class.new(run)
      allow(instance).to receive(:sync_update) # faye
      allow(scraper).to receive(:reindex) # ElasticSearch

      instance.go

      run.reload
      expect(run.tables_added).to eq 1
      expect(run.records_added).to eq 10
      # TODO: Validate we sent the correct requests
      expect(instance).to have_received(:sync_update).twice
      expect(scraper).to have_received(:reindex)
    end
  end

  describe "container helper methods" do
    let(:container) { instance_double(Docker::Container) }

    # FIXME: Fix spec: run_for_container returns nil not run
    # it "retrieves run_id and run for a container" do
    #   allow(Morph::DockerUtils).to receive(:label_value).with(container, "io.morph.run").and_return("123")
    #   expect(described_class.run_id_for_container(container)).to eq(123)
    #
    #   run = Run.create(id: 123)
    #   expect(described_class.run_for_container(container)).to eq(run)
    # end

    it "generates correct docker container labels" do
      owner = User.create(nickname: "mlandauer")
      scraper = create(:scraper, name: "myscraper", owner: owner)
      run = Run.create(id: 456, scraper: scraper)
      runner = described_class.new(run)

      labels = runner.docker_container_labels
      expect(labels["io.morph.run"]).to eq "456"
      expect(labels["io.morph.scraper"]).to eq "mlandauer/myscraper"
    end
  end

  describe "static file utilities" do
    it "copies sqlite database back atomically" do
      Dir.mktmpdir do |dir|
        data_path = File.join(dir, "data")
        FileUtils.mkdir_p(data_path)
        temp_db = Tempfile.new("new_db")
        temp_db.write("new content")
        temp_db.close

        described_class.copy_sqlite_db_back(data_path, temp_db.path)

        expect(File.read(File.join(data_path, "data.sqlite"))).to eq "new content"
      end
    end

    it "adds sqlite db to directory if it exists" do
      Dir.mktmpdir do |dir|
        data_path = File.join(dir, "data")
        FileUtils.mkdir_p(data_path)
        FileUtils.touch(File.join(data_path, "data.sqlite"))

        dest_dir = File.join(dir, "dest")
        FileUtils.mkdir_p(dest_dir)

        described_class.add_sqlite_db_to_directory(data_path, dest_dir)
        expect(File.exist?(File.join(dest_dir, "data.sqlite"))).to be true
      end
    end
  end

  describe "#stop!" do
    # TODO: Test that we can stop the compile stage
    it "is able to stop a scraper running in a continuous loop", slow: true do
      # 1.1 seconds
      owner = User.create(nickname: "mlandauer")
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      fill_scraper_for_run("stream_output_long", run)
      logs = []

      runner = described_class.new(run)
      container_count = Morph::DockerUtils.stopped_containers.count
      runner.go do |_timestamp, _stream, text|
        logs << text
        if text.include? "2..."
          # Putting the stop code in another thread (which is essentially
          # similar to how it works on morph.io for real)
          # If we don't do this we get a "Closed stream (IOError)" which I
          # haven't yet been able to figure out the origins of
          Thread.new { runner.stop! }
        end
      end
      expect(logs.join.include?("2...") || logs.join.include?("3...")).to be true
      expect(Morph::DockerUtils.stopped_containers.count).to eq container_count
      expect(run.database.first_ten_rows).to eq [{ "state" => "started" }]
      expect(run.status_code).to eq 137
    end
  end

  describe ".add_config_defaults_to_directory" do
    before { FileUtils.mkdir("test") }

    after { FileUtils.rm_rf("test") }

    context "with a perl scraper" do
      before { FileUtils.touch("test/scraper.pl") }

      it do
        Dir.mktmpdir do |dir|
          described_class.add_config_defaults_to_directory("test", dir)
          expect(Dir.entries(dir).sort).to eq %w[. .. Procfile app.psgi cpanfile scraper.pl]
          perl = Morph::Language.new(:perl)
          expect(File.read(File.join(dir, "Procfile"))).to eq perl.procfile
          expect(File.read(File.join(dir, "app.psgi")))
            .to eq File.read(perl.default_config_file_path("app.psgi"))
          expect(File.read(File.join(dir, "cpanfile")))
            .to eq File.read(perl.default_config_file_path("cpanfile"))
        end
      end
    end

    context "with a ruby scraper" do
      before { FileUtils.touch("test/scraper.rb") }

      context "when user tries to override Procfile" do
        before do
          File.open("test/Procfile", "w") { |f| f << "scraper: some override" }
          FileUtils.touch("test/Gemfile")
          FileUtils.touch("test/Gemfile.lock")
        end

        it "alwayses use the template Procfile" do
          Dir.mktmpdir do |dir|
            described_class.add_config_defaults_to_directory("test", dir)
            expect(Dir.entries(dir).sort).to eq %w[. .. Gemfile Gemfile.lock Procfile scraper.rb]
            expect(File.read(File.join(dir, "Gemfile"))).to eq ""
            expect(File.read(File.join(dir, "Gemfile.lock"))).to eq ""
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, "Procfile"))).to eq ruby.procfile
          end
        end
      end

      context "when user supplies Gemfile and Gemfile.lock" do
        before do
          FileUtils.touch("test/Gemfile")
          FileUtils.touch("test/Gemfile.lock")
        end

        it "onlies provide a template Procfile" do
          Dir.mktmpdir do |dir|
            described_class.add_config_defaults_to_directory("test", dir)
            expect(Dir.entries(dir).sort).to eq %w[. .. Gemfile Gemfile.lock Procfile scraper.rb]
            expect(File.read(File.join(dir, "Gemfile"))).to eq ""
            expect(File.read(File.join(dir, "Gemfile.lock"))).to eq ""
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, "Procfile"))).to eq ruby.procfile
          end
        end
      end

      context "when user does not supply Gemfile or Gemfile.lock" do
        it "provides a template Gemfile, Gemfile.lock and Procfile" do
          Dir.mktmpdir do |dir|
            described_class.add_config_defaults_to_directory("test", dir)
            expect(Dir.entries(dir).sort).to eq %w[. .. Gemfile Gemfile.lock Procfile scraper.rb]
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, "Gemfile")))
              .to eq File.read(ruby.default_config_file_path("Gemfile"))
            expect(File.read(File.join(dir, "Gemfile.lock")))
              .to eq File.read(ruby.default_config_file_path("Gemfile.lock"))
            expect(File.read(File.join(dir, "Procfile"))).to eq ruby.procfile
          end
        end
      end

      context "when user supplies Gemfile but no Gemfile.lock" do
        before do
          FileUtils.touch("test/Gemfile")
        end

        it "does not try to use the template Gemfile.lock" do
          Dir.mktmpdir do |dir|
            described_class.add_config_defaults_to_directory("test", dir)
            expect(Dir.entries(dir).sort).to eq %w[. .. Gemfile Procfile scraper.rb]
            expect(File.read(File.join(dir, "Gemfile"))).to eq ""
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, "Procfile"))).to eq ruby.procfile
          end
        end
      end
    end
  end

  describe ".remove_hidden_directories" do
    context "with a set of files" do
      before do
        FileUtils.mkdir_p("test/foo")
        FileUtils.mkdir_p("test/.bar")
        FileUtils.touch("test/.a_dot_file.cfg")
        FileUtils.touch("test/.bar/wibble.txt")
        FileUtils.touch("test/one.txt")
        FileUtils.touch("test/Procfile")
        FileUtils.touch("test/two.txt")
        FileUtils.touch("test/foo/three.txt")
        FileUtils.touch("test/Gemfile")
        FileUtils.touch("test/Gemfile.lock")
        FileUtils.touch("test/scraper.rb")
        FileUtils.ln_s("scraper.rb", "test/link.rb")
      end

      after do
        FileUtils.rm_rf("test")
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents("test", dir)
          described_class.remove_hidden_directories(dir)
          expect(Dir.entries(dir).sort).to eq %w[. .. .a_dot_file.cfg Gemfile Gemfile.lock Procfile foo link.rb one.txt scraper.rb two.txt]
        end
      end
    end

    context "with another set of files" do
      before do
        FileUtils.mkdir_p("test/foo")
        FileUtils.touch("test/one.txt")
        FileUtils.touch("test/foo/three.txt")
        FileUtils.touch("test/Gemfile")
        FileUtils.touch("test/Gemfile.lock")
        FileUtils.touch("test/scraper.rb")
      end

      after do
        FileUtils.rm_rf("test")
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents("test", dir)
          described_class.remove_hidden_directories(dir)
          expect(Dir.entries(dir).sort).to eq %w[. .. Gemfile Gemfile.lock foo one.txt scraper.rb]
        end
      end
    end

    context "when user tries to override Procfile" do
      before do
        FileUtils.mkdir_p("test")
        File.open("test/Procfile", "w") { |f| f << "scraper: some override" }
        FileUtils.touch("test/scraper.rb")
      end

      after do
        FileUtils.rm_rf("test")
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents("test", dir)
          described_class.remove_hidden_directories(dir)
          expect(Dir.entries(dir).sort).to eq %w[. .. Procfile scraper.rb]
        end
      end
    end
  end

  def fill_scraper_for_run(scraper_name, run)
    FileUtils.mkdir_p(run.repo_path)
    FileUtils.cp_r(
      File.join(File.dirname(__FILE__), "test_scrapers", "runner_spec", scraper_name, "."),
      run.repo_path
    )
  end
end
