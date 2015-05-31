require 'spec_helper'

describe Morph::DockerRunner do
  # Tests that involve docker are marked as 'docker: true'. This removes
  # them from the default tests. To explicitly run the docker tests:
  # bundle exec rspec spec/lib/morph/docker_runner_spec.rb --tag docker

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
      result = Morph::DockerRunner.compile_and_run(
        @dir, {}, 'foo', []) do |on|
        on.log do |s, c|
          logs << [s, c]
          # puts c
        end
      end

      expect(result.status_code).to eq 255
      expect(logs).to eq [
        [:internalout, "Injecting configuration and compiling...\n"],
        [:internalout, "\e[1G-----> Unable to select a buildpack\n"]
      ]
      expect(Morph::DockerUtils.stopped_containers.count)
        .to eq @container_count
    end

    context 'A ruby scraper with no dependencies' do
      before(:each) do
        File.open(File.join(@dir, 'Procfile'), 'w') do |f|
          f << 'scraper: bundle exec ruby scraper.rb'
        end
        FileUtils.touch(File.join(@dir, 'Gemfile'))
        FileUtils.touch(File.join(@dir, 'Gemfile.lock'))
      end

      it 'should be able to run hello world of course' do
        File.open(File.join(@dir, 'scraper.rb'), 'w') do |f|
          f << "puts 'Hello world!'\n"
        end
        logs = []
        result = Morph::DockerRunner.compile_and_run(
          @dir, {}, 'foo', []) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(result.status_code).to eq 0
        # These logs will actually be different if the compile isn't cached
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "Injecting scraper and running...\n"],
          [:stdout,      "Hello world!\n"]
        ]
        expect(Morph::DockerUtils.stopped_containers.count)
          .to eq @container_count
      end

      it 'should be able to grab a file resulting from running the scraper' do
        File.open(File.join(@dir, 'scraper.rb'), 'w') do |f|
          f << "File.open('foo.txt', 'w') { |f| f << 'Hello World!'}\n"
        end
        logs = []
        result = Morph::DockerRunner.compile_and_run(
          @dir, {}, 'foo', ['foo.txt', 'bar']) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(result.status_code).to eq 0
        expect(result.files).to eq('foo.txt' => 'Hello World!', 'bar' => nil)
        # These logs will actually be different if the compile isn't cached
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "Injecting scraper and running...\n"]
        ]
        expect(Morph::DockerUtils.stopped_containers.count)
          .to eq @container_count
      end

      it 'should be able to pass environment variables' do
        File.open(File.join(@dir, 'scraper.rb'), 'w') do |f|
          f << "puts ENV['AN_ENV_VARIABLE']\n"
        end
        logs = []
        result = Morph::DockerRunner.compile_and_run(
          @dir, { 'AN_ENV_VARIABLE' => 'Hello world!' }, 'foo', []) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(result.status_code).to eq 0
        # These logs will actually be different if the compile isn't cached
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "Injecting scraper and running...\n"],
          [:stdout,      "Hello world!\n"]
        ]
      end

      it 'should return the ip address of the container' do
        File.open(File.join(@dir, 'scraper.rb'), 'w') do |f|
          f << <<-EOF
require 'socket'
address = Socket.ip_address_list.find do |i|
  i.ipv4? && !i.ipv4_loopback?
end
File.open("ip_address", "w") {|f| f << address.ip_address}
          EOF
        end
        ip_address = nil
        result = Morph::DockerRunner.compile_and_run(
          @dir, {}, 'foo', ['ip_address']) do |on|
          on.ip_address { |ip| ip_address = ip }
        end
        expect(result.status_code).to eq 0
        # These logs will actually be different if the compile isn't cached
        expect(ip_address).to eq result.files['ip_address']
      end

      it 'should return a non-zero error code if the scraper fails' do
        File.open(File.join(@dir, 'scraper.rb'), 'w') do |f|
          f << <<-EOF
This is not going to run as ruby code so should return an error
          EOF
        end
        logs = []
        result = Morph::DockerRunner.compile_and_run(
          @dir, {}, 'foo', []) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(result.status_code).to eq 1
        # These logs will actually be different if the compile isn't cached
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "Injecting scraper and running...\n"],
          [:stderr,
           "scraper.rb:1: syntax error, unexpected tIDENTIFIER, expecting '('\n" \
           "This is not going to run as ruby code so should return an error\n" \
           "                 ^\n" \
           "scraper.rb:1: void value expression\n"]
        ]
      end
    end

    skip 'should cache the compile' do
    end
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
