require 'spec_helper'

describe Morph::DockerRunner do
  # Tests that involve docker are marked as 'docker: true'. This stops
  # them from running on travis ci which doesn't have access to a docker
  # server

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
      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) do |s, c|
        logs << [s, c]
      end

      expect(c).to be_nil
      expect(logs).to eq [
        [:internalout, "Injecting configuration and compiling...\n"],
        [:internalout, "\e[1G-----> Unable to select a buildpack\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    it 'should be able to run hello world' do
      copy_test_scraper('hello_world_js')

      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      result = Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        logs << [s, c]
      end
      expect(result.status_code).to eq 0
      expect(logs).to eq [[:stdout, "Hello world!\n"]]
    end

    it 'should be able to run hello world of course' do
      copy_test_scraper('hello_world_ruby')

      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      result = Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        logs << [s, c]
      end
      expect(result.status_code).to eq 0
      expect(logs).to eq [
        [:stdout,      "Hello world!\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    it 'should be able to grab a file resulting from running the scraper' do
      copy_test_scraper('write_to_file_ruby')

      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      result = Morph::DockerRunner.attach_to_run_and_finish(
        c, ['foo.txt', 'bar']) {}
      expect(result.status_code).to eq 0
      expect(result.files).to eq('foo.txt' => 'Hello World!', 'bar' => nil)
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    it 'should be able to pass environment variables' do
      copy_test_scraper('display_env_ruby')

      logs = []
      c, _i3 = Morph::DockerRunner.compile_and_start_run(
        @dir, { 'AN_ENV_VARIABLE' => 'Hello world!' }, {}) {}
      result = Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        logs << [s, c]
      end
      expect(result.status_code).to eq 0
      # These logs will actually be different if the compile isn't cached
      expect(logs).to eq [
        [:stdout,      "Hello world!\n"]
      ]
    end

    it 'should have an env variable set for python requests library' do
      copy_test_scraper('display_request_env_ruby')

      c, _i3 = Morph::DockerRunner.compile_and_start_run(
        @dir, {}, {}) {}
      logs = []
      result = Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        logs << [s, c]
      end
      expect(result.status_code).to eq 0
      expect(logs).to eq [[:stdout, "/etc/ssl/certs/ca-certificates.crt\n"]]
    end

    it 'should return the ip address of the container' do
      copy_test_scraper('ip_address_ruby')

      ip_address = nil
      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      ip_address = c.json['NetworkSettings']['IPAddress']
      result = Morph::DockerRunner.attach_to_run_and_finish(
        c, ['ip_address']) {}
      expect(result.status_code).to eq 0
      # These logs will actually be different if the compile isn't cached
      expect(ip_address).to eq result.files['ip_address']
    end

    it 'should return a non-zero error code if the scraper fails' do
      copy_test_scraper('failing_scraper_ruby')

      logs = []
      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      result = Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        logs << [s, c]
      end
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
      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) do |s, c|
        logs << [Time.now, c]
      end
      result = Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        logs << [Time.now, c]
      end
      start_time = logs.find{|l| l[1] == "Started!\n"}[0]
      end_time = logs.find{|l| l[1] == "Finished!\n"}[0]
      expect(end_time - start_time).to be_within(0.1).of(1.0)
    end

    it 'should be able to reconnect to a running container' do
      copy_test_scraper('stream_output_ruby')

      logs = []
      # TODO Really should be able to call compile_and_start_run without a block
      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      # Simulate the log process stopping
      last_timestamp = nil
      expect {Morph::DockerRunner.attach_to_run_and_finish(c, []) do |timestamp, s, c|
        last_timestamp = timestamp
        logs << c
        if c == "2...\n"
          raise Sidekiq::Shutdown
        end
      end}.to raise_error Sidekiq::Shutdown
      expect(logs).to eq ["Started!\n", "1...\n", "2...\n"]
      # Now restart the log process using the timestamp of the last log entry
      Morph::DockerRunner.attach_to_run_and_finish(c, [], last_timestamp) do |timestamp, s, c|
        logs << c
      end
      expect(logs).to eq ["Started!\n", "1...\n", "2...\n", "3...\n", "4...\n", "5...\n", "6...\n", "7...\n", "8...\n", "9...\n", "10...\n", "Finished!\n"]
    end

    it 'should be able to limit the amount of log output' do
      copy_test_scraper('stream_output_ruby')

      c, _i3 = Morph::DockerRunner.compile_and_start_run(@dir, {}, {}) {}
      logs = []
      Morph::DockerRunner.attach_to_run_and_finish(c, [], nil, 5) do |timestamp, s, c|
        logs << [s, c]
      end
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
