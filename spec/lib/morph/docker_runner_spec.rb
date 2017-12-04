require 'spec_helper'
require 'memory_profiler'

describe Morph::DockerRunner do
  # Tests that involve docker are marked as 'docker: true'.

  # These are integration tests with the whole docker server and the
  # docker images that are used. Also, the tests are very slow!
  describe '.compile_and_run', docker: true do
    before(:each) do
      @dir = Dir.mktmpdir
      @container_count = Morph::DockerUtils.stopped_containers.count
    end

    after(:each) { FileUtils.remove_entry @dir }

    it "should let me know that it can't select a buildpack" do
      logs = []
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) do |s, c|
        logs << [s, c]
      end

      expect(c).to be_nil
      expect(logs).to eq [
        [:internalout, "Injecting configuration and compiling...\n"],
        [:internalout, "\e[1G       \e[1G-----> Unable to select a buildpack\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    it "should stop if a python compile fails" do
      copy_test_scraper('failing_compile_python')
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      expect(c).to be_nil
    end

    it 'should be able to run hello world' do
      copy_test_scraper('hello_world_js')

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [s, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      expect(result.status_code).to eq 0
      expect(logs).to eq [[:stdout, "Hello world!\n"]]
    end

    def with_smaller_chunk_size(&block)
      chunk_size = Excon.defaults[:chunk_size]
      Excon.defaults[:chunk_size] = 1024
      result = yield
      Excon.defaults[:chunk_size] = chunk_size
      result
    end

    it 'should not allocate and retain too much memory when running scraper' do
      copy_test_scraper('hello_world_js')

      # Limit the buffer size just for testing
      report = MemoryProfiler.report do
        with_smaller_chunk_size do
          c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
          Morph::DockerRunner.attach_to_run(c) {}
          Morph::DockerRunner.finish(c, [])
        end
      end

      #report.pretty_print
      expect(report.total_allocated_memsize).to be < 2_000_000
      expect(report.total_retained_memsize < 15_000)
    end

    it "should attach the container to a special morph-only docker network" do
      copy_test_scraper('hello_world_js')

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      expect(c.json['HostConfig']['NetworkMode']).to eq 'morph'
      # Check that the network has some things set
      network_info = Docker::Network.get('morph').info
      expect(network_info['Options']['com.docker.network.bridge.name']).to eq "morph"
      expect(network_info['Options']["com.docker.network.bridge.enable_icc"]).to eq 'false'
      # We're not hardcoding the subnet anymore. So, have to disable the test below
      #expect(network_info['IPAM']['Config'].first['Subnet']).to eq '192.168.0.0/16'
      c.kill
      c.delete
    end

    it 'should be able to run hello world from a sub-directory' do
      copy_test_scraper('hello_world_subdirectory_js')

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [s, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      expect(result.status_code).to eq 0
      expect(logs).to eq [[:stdout, "Hello world!\n"]]
    end

    it 'should cache the compile stage' do
      copy_test_scraper('hello_world_js')

      # Do the compile once to make sure the cache is primed
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      # Clean up container because we're not calling finish
      # which normally does the cleanup
      c.kill
      c.delete

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) do |s, c|
        logs << [s, c]
      end
      c.kill
      c.delete
      expect(logs).to eq [
        [:internalout, "Injecting configuration and compiling...\n"],
        [:internalout, "Injecting scraper and running...\n"]
      ]
    end

    it 'should be able to run hello world of course' do
      copy_test_scraper('hello_world_ruby')

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [s, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      expect(result.status_code).to eq 0
      expect(logs).to eq [
        [:stdout,      "Hello world!\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    it 'should be able to grab a file resulting from running the scraper' do
      copy_test_scraper('write_to_file_ruby')

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      Morph::DockerRunner.attach_to_run(c) {}
      result = Morph::DockerRunner.finish(c, ['foo.txt', 'bar'])
      expect(result.status_code).to eq 0
      expect(result.files.keys).to eq(['foo.txt', 'bar'])
      expect(result.files['foo.txt'].read).to eq 'Hello World!'
      expect(result.files['bar']).to eq nil
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    it 'should be able to pass environment variables' do
      copy_test_scraper('display_env_ruby')

      logs = []
      c = Morph::DockerRunner.compile_and_start_run(
        @dir, { 'AN_ENV_VARIABLE' => 'Hello world!' }, {}) {}
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [s, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      expect(result.status_code).to eq 0
      # These logs will actually be different if the compile isn't cached
      expect(logs).to eq [
        [:stdout,      "Hello world!\n"]
      ]
    end

    it 'should have an env variable set for python requests library' do
      copy_test_scraper('display_request_env_ruby')

      c = Morph::DockerRunner.compile_and_start_run(
        @dir, {}, {}) {}
      logs = []
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [s, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      expect(result.status_code).to eq 0
      expect(logs).to eq [[:stdout, "/etc/ssl/certs/ca-certificates.crt\n"]]
    end

    it 'should return the ip address of the container' do
      copy_test_scraper('ip_address_ruby')

      ip_address = nil
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      ip_address = Morph::DockerUtils.ip_address_of_container(c)
      Morph::DockerRunner.attach_to_run(c) {}
      result = Morph::DockerRunner.finish(c, ['ip_address'])
      expect(result.status_code).to eq 0
      # Check that ip address lies in the expected subnet
      expect(ip_address).to eq result.files['ip_address'].read
    end

    it 'should return a non-zero error code if the scraper fails' do
      copy_test_scraper('failing_scraper_ruby')

      logs = []
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [s, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      expect(result.status_code).to eq 1
      expect(logs).to eq [
        [:stderr, "scraper.rb:1: syntax error, unexpected tIDENTIFIER, expecting '('\n"],
        [:stderr, "This is not going to run as ruby code so should return an error\n"],
        [:stderr, "                 ^\n"],
        [:stderr, "scraper.rb:1: void value expression\n"]
      ]
    end

    it 'should stream output if the right things are set for the language' do
      copy_test_scraper('stream_output_ruby')

      logs = []
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) do |s, c|
        logs << [Time.now, c]
      end
      Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        logs << [Time.now, c]
      end
      result = Morph::DockerRunner.finish(c, [])
      start_time = logs.find{|l| l[1] == "Started!\n"}[0]
      end_time = logs.find{|l| l[1] == "Finished!\n"}[0]
      expect(end_time - start_time).to be_within(0.1).of(1.0)
    end

    it 'should be able to reconnect to a running container' do
      copy_test_scraper('stream_output_ruby')

      logs = []
      # TODO Really should be able to call compile_and_start_run without a block
      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      # Simulate the log process stopping
      last_timestamp = nil
      expect {Morph::DockerRunner.attach_to_run(c) do |timestamp, s, c|
        last_timestamp = timestamp
        logs << c
        if c == "2...\n"
          raise Sidekiq::Shutdown
        end
      end}.to raise_error Sidekiq::Shutdown
      expect(logs).to eq ["Started!\n", "1...\n", "2...\n"]
      # Now restart the log process using the timestamp of the last log entry
      Morph::DockerRunner.attach_to_run(c, last_timestamp) do |timestamp, s, c|
        logs << c
      end
      Morph::DockerRunner.finish(c, [])
      expect(logs).to eq ["Started!\n", "1...\n", "2...\n", "3...\n", "4...\n", "5...\n", "6...\n", "7...\n", "8...\n", "9...\n", "10...\n", "Finished!\n"]
    end

    it 'should be able to limit the amount of log output' do
      copy_test_scraper('stream_output_ruby')

      c = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}, 5) {}
      logs = []
      Morph::DockerRunner.attach_to_run(c, nil) do |timestamp, s, c|
        logs << [s, c]
      end
      Morph::DockerRunner.finish(c, [])
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

  skip 'should cache the compile' do
  end

  context 'a set of files' do
    before :each do
      FileUtils.mkdir_p 'test/foo'
      FileUtils.mkdir_p 'test/.bar'
      FileUtils.touch 'test/.a_dot_file.cfg'
      FileUtils.touch 'test/.bar/wibble.txt'
      FileUtils.touch 'test/one.txt'
      FileUtils.touch 'test/Procfile'
      FileUtils.touch 'test/two.txt'
      FileUtils.touch 'test/foo/three.txt'
      FileUtils.touch 'test/Gemfile'
      FileUtils.touch 'test/Gemfile.lock'
      FileUtils.touch 'test/scraper.rb'
      FileUtils.ln_s 'scraper.rb', 'test/link.rb'
    end

    after :each do
      FileUtils.rm_rf 'test'
    end

    describe '.copy_config_to_directory' do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.copy_config_to_directory('test', dir, true)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', 'Gemfile', 'Gemfile.lock', 'Procfile']
          expect(File.read(File.join(dir, 'Gemfile'))).to eq ''
          expect(File.read(File.join(dir, 'Gemfile.lock'))).to eq ''
          expect(File.read(File.join(dir, 'Procfile'))).to eq ''
        end
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.copy_config_to_directory('test', dir, false)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', '.a_dot_file.cfg', '.bar', 'foo', 'link.rb', 'one.txt',
            'scraper.rb', 'two.txt']
          expect(Dir.entries(File.join(dir, '.bar')).sort).to eq [
            '.', '..', 'wibble.txt']
          expect(Dir.entries(File.join(dir, 'foo')).sort).to eq [
            '.', '..', 'three.txt']
          expect(File.read(File.join(dir, '.a_dot_file.cfg'))).to eq ''
          expect(File.read(File.join(dir, '.bar', 'wibble.txt'))).to eq ''
          expect(File.read(File.join(dir, 'foo/three.txt'))).to eq ''
          expect(File.read(File.join(dir, 'one.txt'))).to eq ''
          expect(File.read(File.join(dir, 'scraper.rb'))).to eq ''
          expect(File.read(File.join(dir, 'two.txt'))).to eq ''
          expect(File.readlink(File.join(dir, 'link.rb'))).to eq 'scraper.rb'
        end
      end
    end
  end

  context 'another set of files' do
    before :each do
      FileUtils.mkdir_p('test/foo')
      FileUtils.touch('test/one.txt')
      FileUtils.touch('test/foo/three.txt')
      FileUtils.touch('test/Gemfile')
      FileUtils.touch('test/Gemfile.lock')
      FileUtils.touch('test/scraper.rb')
    end

    after :each do
      FileUtils.rm_rf('test')
    end

    describe '.copy_config_to_directory' do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.copy_config_to_directory('test', dir, true)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', 'Gemfile', 'Gemfile.lock']
          expect(File.read(File.join(dir, 'Gemfile'))).to eq ''
          expect(File.read(File.join(dir, 'Gemfile.lock'))).to eq ''
        end
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.copy_config_to_directory('test', dir, false)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', 'foo', 'one.txt', 'scraper.rb']
          expect(Dir.entries(File.join(dir, 'foo')).sort).to eq [
            '.', '..', 'three.txt']
          expect(File.read(File.join(dir, 'foo/three.txt'))).to eq ''
          expect(File.read(File.join(dir, 'one.txt'))).to eq ''
          expect(File.read(File.join(dir, 'scraper.rb'))).to eq ''
        end
      end
    end
  end

  context 'user tries to override Procfile' do
    before :each do
      FileUtils.mkdir_p('test')
      File.open('test/Procfile', 'w') { |f| f << 'scraper: some override' }
      FileUtils.touch('test/scraper.rb')
    end

    after :each do
      FileUtils.rm_rf('test')
    end

    describe '.copy_config_to_directory' do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.copy_config_to_directory('test', dir, true)
          expect(Dir.entries(dir).sort).to eq ['.', '..', 'Procfile']
          expect(File.read(File.join(dir, 'Procfile')))
            .to eq 'scraper: some override'
        end
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.copy_config_to_directory('test', dir, false)
          expect(Dir.entries(dir).sort).to eq ['.', '..', 'scraper.rb']
          expect(File.read(File.join(dir, 'scraper.rb'))).to eq ''
        end
      end
    end
  end
end

def copy_test_scraper(name)
  FileUtils::cp_r(
    File.join(File.dirname(__FILE__), 'test_scrapers', 'docker_runner_spec', name, '.'),
    @dir)
end
