# typed: false
# frozen_string_literal: true

require "spec_helper"
require "memory_profiler"

describe Morph::DockerRunner do
  # Tests that involve docker are marked as 'docker: true'.

  # These are integration tests with the whole docker server and the
  # docker images that are used. Also, the tests are very slow!
  describe ".compile_and_run", docker: true do
    let!(:dir) { Dir.mktmpdir }
    let(:platform) do
      Scraper.new(name: dir).platform
    end
    let!(:container_count) { Morph::DockerUtils.stopped_containers.count }
    let(:docker_output) { [] }

    after do |example|
      FileUtils.remove_entry dir
      if example.exception && docker_output
        puts "\n=== DOCKER BUILD OUTPUT ==="
        docker_output.each do |stream, text|
          puts "#{stream}: #{text}" if text&.strip.present?
        end
        puts "=========================\n"
      end
    end

    it "lets me know that it can't select a buildpack", slow: true do # 5.12 seconds
      c = described_class.compile_and_start_run(repo_path: dir) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end

      # For some reason (which I don't understand) on travis it returns
      # extra lines with carriage returns. So, ignore these
      pruned_docker_output = docker_output.reject { |l| l[1] == "\n" }

      expect(c).to be_nil
      expect(pruned_docker_output).to eq [
        [:internalout, "Injecting configuration and compiling...\n"],
        [:internalout, "\e[1G       \e[1G-----> Unable to select a buildpack\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq container_count
    end

    it "stops if a python compile fails", slow: true do # 5.2 seconds
      copy_test_scraper("failing_compile_python")
      c = described_class.compile_and_start_run(repo_path: dir) do |_timestamp, stream, text|
        docker_output  << [stream, text]
      end
      expect(c).to be_nil
    end

    it "is able to run nodejs example" do
      copy_example_scraper("nodejs")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output  << [stream, text]
      end
      expect(c).not_to be_nil
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output.last).to eq [:stdout, "1: Example Domain\n"]
    end

    it "is able to run perl example" do
      copy_example_scraper("perl")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      pending("FIXME: Fix perl example test - it works in production but not in test")
      expect(c).not_to be_nil
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output.last).to eq [:stdout, "1: Example Domain\n"]
    end

    it "is able to run php example" do
      copy_example_scraper("php")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      expect(c).not_to be_nil
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output.last).to eq [:stdout, "1: Example Domain\n"]
    end

    it "is able to run python example", slow: true do # 7.2 seconds
      copy_example_scraper("python")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      pending("FIXME: Fix python example test - requires heroku-24 platform to be implemented")
      expect(c).not_to be_nil
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output.last).to eq [:stdout, "1: Example Domain\n"]
    end

    # FIXME: test python when we add heroku-24 as ceder-4 and heroku-18 can't find any python versions

    it "is able to run ruby example" do
      copy_example_scraper("ruby")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      expect(c).not_to be_nil
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output.last).to eq [:stdout, "1: Example Domain\n"]
    end

    it "is able to run hello world js on heroku-18" do
      copy_test_scraper("hello_world_js")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      expect(c).not_to be_nil
      logs = []
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        logs << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(logs).to eq [[:stdout, "Hello world!\n"]]
    end

    def with_smaller_chunk_size
      chunk_size = Excon.defaults[:chunk_size]
      Excon.defaults[:chunk_size] = 1024
      result = yield
      Excon.defaults[:chunk_size] = chunk_size
      result
    end

    it "does not allocate and retain too much memory when running scraper" do
      copy_test_scraper("hello_world_js")

      # Limit the buffer size just for testing
      report = MemoryProfiler.report do
        with_smaller_chunk_size do
          c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
            docker_output << [stream, text]
          end
          expect(c).not_to be_nil
          described_class.attach_to_run(c)
          described_class.finish(c, [])
        end
      end

      # report.pretty_print
      expect(report.total_allocated_memsize).to be < 2_000_000
      # I think increase in retained memory is due to sorbet typechecking and there was a bug fixed where
      # the inequality wasn't being properly checked
      expect(report.total_retained_memsize).to be < 55_000
    end

    it "attaches the container to a special morph-only docker network" do
      copy_test_scraper("hello_world_js")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output  << [stream, text]
      end
      expect(c).not_to be_nil
      expect(c.json["HostConfig"]["NetworkMode"]).to eq "morph"
      # Check that the network has some things set
      network_info = Docker::Network.get("morph").info
      expect(network_info["Options"]["com.docker.network.bridge.name"]).to eq "morph"
      expect(network_info["Options"]["com.docker.network.bridge.enable_icc"]).to eq "false"
      # We're not hardcoding the subnet anymore. So, have to disable the test below
      # expect(network_info['IPAM']['Config'].first['Subnet']).to eq '192.168.0.0/16'
      c.kill
      c.delete
    end

    it "is not able to run hello world from a sub-directory", slow: true do
      copy_test_scraper("hello_world_subdirectory_js")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output  << [stream, text]
      end
      expect(c).to be_nil
      # logs = []
      # described_class.attach_to_run(c) do |_timestamp, stream, text|
      #   logs << [stream, text]
      # end
      #
      # result = described_class.finish(c, [])
      # expect(result.status_code).to eq 0
      # expect(logs).to eq [[:stdout, "Hello world!\n"]]
    end

    it "caches the compile stage" do
      copy_test_scraper("hello_world_js")

      # Do the compile once to make sure the cache is primed
      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        docker_output  << [stream, text]
      end
      expect(c).not_to be_nil
      logs = []
      # Clean up container because we're not calling finish
      # which normally does the cleanup
      c.kill
      c.delete

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, stream, text|
        logs << [stream, text]
        docker_output << [stream, text]
      end

      # For some reason (which I don't understand) on travis it returns
      # extra lines with carriage returns. So, ignore these
      logs = logs.reject { |l| l[1] == "\n" }

      c.kill
      c.delete
      expect(logs).to eq [
        [:internalout, "Injecting configuration and compiling...\n"],
        [:internalout, "Injecting scraper and running...\n"]
      ]
    end

    it "is able to run hello world of course" do
      copy_test_scraper("hello_world_ruby")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform)
      docker_output = []
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output).to eq [
        [:stdout, "Hello world!\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq container_count
    end

    it "is able to grab a file resulting from running the scraper" do
      copy_test_scraper("write_to_file_ruby")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform)
      described_class.attach_to_run(c)
      result = described_class.finish(c, ["foo.txt", "bar"])
      expect(result.status_code).to eq 0
      expect(result.files.keys).to eq(["foo.txt", "bar"])
      expect(result.files["foo.txt"].read).to eq "Hello World!"
      expect(result.files["bar"]).to be_nil
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq container_count
    end

    it "is able to pass environment variables" do
      copy_test_scraper("display_env_ruby")

      docker_output = []
      c = described_class.compile_and_start_run(
        repo_path: dir, env_variables: { "AN_ENV_VARIABLE" => "Hello world!" }, platform: platform
      )
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      # These logs will actually be different if the compile isn't cached
      expect(docker_output).to eq [
        [:stdout, "Hello world!\n"]
      ]
    end

    it "has an env variable set for python requests library" do
      copy_test_scraper("display_request_env_ruby")

      c = described_class.compile_and_start_run(
        repo_path: dir, platform: platform
      )
      docker_output = []
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 0
      expect(docker_output).to eq [[:stdout, "/etc/ssl/certs/ca-certificates.crt\n"]]
    end

    it "returns the ip address of the container" do
      copy_test_scraper("ip_address_ruby")

      c = described_class.compile_and_start_run(repo_path: dir, platform: platform)
      ip_address = Morph::DockerUtils.ip_address_of_container(c)
      described_class.attach_to_run(c)
      result = described_class.finish(c, ["ip_address"])
      expect(result.status_code).to eq 0
      # Check that ip address lies in the expected subnet
      expect(ip_address).to eq result.files["ip_address"].read
    end

    it "returns a non-zero error code if the scraper fails" do
      copy_test_scraper("failing_scraper_ruby")

      docker_output = []
      c = described_class.compile_and_start_run(repo_path: dir, platform: platform)
      described_class.attach_to_run(c) do |_timestamp, stream, text|
        docker_output << [stream, text]
      end
      result = described_class.finish(c, [])
      expect(result.status_code).to eq 1
      expect(docker_output).to eq [
        [:stderr, "scraper.rb:1: syntax error, unexpected tIDENTIFIER, expecting '('\n"],
        [:stderr, "This is not going to run as ruby code so should return an error\n"],
        [:stderr, "                 ^\n"],
        [:stderr, "scraper.rb:1: void value expression\n"]
      ]
    end

    it "streams output if the right things are set for the language" do
      copy_test_scraper("stream_output_ruby")

      docker_output = []
      c = described_class.compile_and_start_run(repo_path: dir, platform: platform) do |_timestamp, _stream, text|
        docker_output << [Time.zone.now, text]
      end
      described_class.attach_to_run(c) do |_timestamp, _stream, text|
        docker_output << [Time.zone.now, text]
      end
      described_class.finish(c, [])
      start_time = docker_output.find { |l| l[1] == "Started!\n" }[0]
      end_time = docker_output.find { |l| l[1] == "Finished!\n" }[0]
      expect(end_time - start_time).to be_within(0.1).of(1.0)
    end

    it "is able to reconnect to a running container" do
      copy_test_scraper("stream_output_ruby")

      logs = []
      c = described_class.compile_and_start_run(repo_path: dir, platform: platform)
      # Simulate the log process stopping
      last_timestamp = nil
      expect do
        described_class.attach_to_run(c) do |timestamp, _stream, text|
          last_timestamp = timestamp
          logs << text

          raise Sidekiq::Shutdown if text == "2...\n"
        end
      end.to raise_error Sidekiq::Shutdown
      expect(logs).to eq ["Started!\n", "1...\n", "2...\n"]
      # Now restart the log process using the timestamp of the last log entry
      described_class.attach_to_run(c, last_timestamp) do |_timestamp, _stream, text|
        logs << text
      end
      described_class.finish(c, [])
      expect(logs).to eq ["Started!\n", "1...\n", "2...\n", "3...\n", "4...\n", "5...\n", "6...\n", "7...\n", "8...\n", "9...\n", "10...\n", "Finished!\n"]
    end

    it "is able to limit the amount of log output" do
      copy_test_scraper("stream_output_ruby")

      c = described_class.compile_and_start_run(repo_path: dir, max_lines: 5, platform: platform)
      logs = []
      described_class.attach_to_run(c, nil) do |_timestamp, stream, text|
        logs << [stream, text]
      end
      described_class.finish(c, [])
      expect(logs).to eq [
        [:stdout, "Started!\n"],
        [:stdout, "1...\n"],
        [:stdout, "2...\n"],
        [:stdout, "3...\n"],
        [:stdout, "4...\n"],
        [:internalerr, "\nToo many lines of output! Your scraper will continue uninterrupted. There will just be no further output displayed\n"]
      ]
    end
  end

  context "with a set of files" do
    before do
      FileUtils.mkdir_p "test/foo"
      FileUtils.mkdir_p "test/.bar"
      FileUtils.touch "test/.a_dot_file.cfg"
      FileUtils.touch "test/.bar/wibble.txt"
      FileUtils.touch "test/one.txt"
      FileUtils.touch "test/Procfile"
      FileUtils.touch "test/two.txt"
      FileUtils.touch "test/foo/three.txt"
      FileUtils.touch "test/Gemfile"
      FileUtils.touch "test/Gemfile.lock"
      FileUtils.touch "test/scraper.rb"
      FileUtils.ln_s "scraper.rb", "test/link.rb"
    end

    after do
      FileUtils.rm_rf "test"
    end

    describe ".copy_config_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          described_class.copy_config_to_directory("test", dir, true)
          expect(Dir.entries(dir).sort).to eq [
            ".", "..", "Gemfile", "Gemfile.lock", "Procfile"
          ]
          expect(File.read(File.join(dir, "Gemfile"))).to eq ""
          expect(File.read(File.join(dir, "Gemfile.lock"))).to eq ""
          expect(File.read(File.join(dir, "Procfile"))).to eq ""
        end
      end

      it do
        Dir.mktmpdir do |dir|
          described_class.copy_config_to_directory("test", dir, false)
          expect(Dir.entries(dir).sort).to eq [
            ".", "..", ".a_dot_file.cfg", ".bar", "foo", "link.rb", "one.txt",
            "scraper.rb", "two.txt"
          ]
          expect(Dir.entries(File.join(dir, ".bar")).sort).to eq [
            ".", "..", "wibble.txt"
          ]
          expect(Dir.entries(File.join(dir, "foo")).sort).to eq [
            ".", "..", "three.txt"
          ]
          expect(File.read(File.join(dir, ".a_dot_file.cfg"))).to eq ""
          expect(File.read(File.join(dir, ".bar", "wibble.txt"))).to eq ""
          expect(File.read(File.join(dir, "foo/three.txt"))).to eq ""
          expect(File.read(File.join(dir, "one.txt"))).to eq ""
          expect(File.read(File.join(dir, "scraper.rb"))).to eq ""
          expect(File.read(File.join(dir, "two.txt"))).to eq ""
          expect(File.readlink(File.join(dir, "link.rb"))).to eq "scraper.rb"
        end
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

    describe ".copy_config_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          described_class.copy_config_to_directory("test", dir, true)
          expect(Dir.entries(dir).sort).to eq [
            ".", "..", "Gemfile", "Gemfile.lock"
          ]
          expect(File.read(File.join(dir, "Gemfile"))).to eq ""
          expect(File.read(File.join(dir, "Gemfile.lock"))).to eq ""
        end
      end

      it do
        Dir.mktmpdir do |dir|
          described_class.copy_config_to_directory("test", dir, false)
          expect(Dir.entries(dir).sort).to eq [
            ".", "..", "foo", "one.txt", "scraper.rb"
          ]
          expect(Dir.entries(File.join(dir, "foo")).sort).to eq [
            ".", "..", "three.txt"
          ]
          expect(File.read(File.join(dir, "foo/three.txt"))).to eq ""
          expect(File.read(File.join(dir, "one.txt"))).to eq ""
          expect(File.read(File.join(dir, "scraper.rb"))).to eq ""
        end
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

    describe ".copy_config_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          described_class.copy_config_to_directory("test", dir, true)
          expect(Dir.entries(dir).sort).to eq [".", "..", "Procfile"]
          expect(File.read(File.join(dir, "Procfile")))
            .to eq "scraper: some override"
        end
      end

      it do
        Dir.mktmpdir do |dir|
          described_class.copy_config_to_directory("test", dir, false)
          expect(Dir.entries(dir).sort).to eq [".", "..", "scraper.rb"]
          expect(File.read(File.join(dir, "scraper.rb"))).to eq ""
        end
      end
    end
  end
end

def copy_test_scraper(name)
  FileUtils.cp_r(
    File.join(File.dirname(__FILE__), "test_scrapers", "docker_runner_spec", name, "."),
    dir
  )
end

def copy_example_scraper(name)
  src_dir = File.join(File.dirname(__FILE__), "..", "..", "..", "default_files", name, "template", ".")
  FileUtils.cp_r(src_dir, dir)
  # Create Procfile (normally done by Morph::Runner.add_config_defaults_to_directory)
  File.open(File.join(dir, "Procfile"), "w") do |f|
    f << Morph::Language.new(name.to_sym).procfile
  end
end
