require 'spec_helper'

describe Morph::DockerRunner do
  # Tests that involve docker are marked as 'docker: true'. This removes
  # them from the default tests. To explicitly run the docker tests:
  # bundle exec rspec spec/lib/morph/docker_runner_spec.rb --tag docker

  # These are integration tests with the whole docker server and the
  # docker images that are used. Also, the tests are very slow!
  describe '.compile_and_run', docker: true do
    it "should let me know that it can't select a buildpack" do
      Dir.mktmpdir do |dir|
        logs = []
        container_count = Morph::DockerUtils.stopped_containers.count
        status_code, _data_with_stripped_paths, _time_params =
          Morph::DockerRunner.compile_and_run(dir, {}, 'foo', []) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(status_code).to eq 255
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "\e[1G-----> Unable to select a buildpack\n"]
        ]
        expect(Morph::DockerUtils.stopped_containers.count)
          .to eq container_count
      end
    end

    it 'should be able to run hello world of course' do
      Dir.mktmpdir do |dir|
        File.open(File.join(dir, 'Procfile'), 'w') do |f|
          f << 'scraper: bundle exec ruby scraper.rb'
        end
        FileUtils.touch(File.join(dir, 'Gemfile'))
        FileUtils.touch(File.join(dir, 'Gemfile.lock'))
        File.open(File.join(dir, 'scraper.rb'), 'w') do |f|
          f << "puts 'Hello world!'\n"
        end
        logs = []
        container_count = Morph::DockerUtils.stopped_containers.count
        status_code, _files, _time_params =
          Morph::DockerRunner.compile_and_run(dir, {}, 'foo', []) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(status_code).to eq 0
        # These logs will actually be different if the compile isn't cached
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "Injecting scraper and running...\n"],
          [:stdout,      "Hello world!\n"]
        ]
        expect(Morph::DockerUtils.stopped_containers.count)
          .to eq container_count
      end
    end

    it 'should be able to grab a file resulting from running the scraper' do
      Dir.mktmpdir do |dir|
        File.open(File.join(dir, 'Procfile'), 'w') do |f|
          f << 'scraper: bundle exec ruby scraper.rb'
        end
        FileUtils.touch(File.join(dir, 'Gemfile'))
        FileUtils.touch(File.join(dir, 'Gemfile.lock'))
        File.open(File.join(dir, 'scraper.rb'), 'w') do |f|
          f << "File.open('foo.txt', 'w') { |f| f << 'Hello World!'}\n"
        end
        logs = []
        container_count = Morph::DockerUtils.stopped_containers.count
        status_code, files, _time_params =
          Morph::DockerRunner.compile_and_run(
            dir, {}, 'foo', ['foo.txt', 'bar']) do |on|
          on.log do |s, c|
            logs << [s, c]
            # puts c
          end
        end
        expect(status_code).to eq 0
        expect(files).to eq('foo.txt' => 'Hello World!', 'bar' => nil)
        # These logs will actually be different if the compile isn't cached
        expect(logs).to eq [
          [:internalout, "Injecting configuration and compiling...\n"],
          [:internalout, "Injecting scraper and running...\n"]
        ]
        expect(Morph::DockerUtils.stopped_containers.count)
          .to eq container_count
      end
    end

    skip 'should be able to pass environment variables' do
    end

    skip 'should cache the compile' do
    end

    skip 'should return the ip address of the container' do
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
