require 'spec_helper'
# To define Sidekiq::Shutdown
require 'sidekiq/cli'

describe Morph::Runner do
  describe '.go', docker: true do
    it 'should run without an associated scraper' do
      owner = User.create(nickname: 'mlandauer')
      run = Run.create(owner: owner)
      run.database.clear
      expect(run.database.no_rows).to eq 0
      FileUtils.mkdir_p(run.repo_path)
      File.open(File.join(run.repo_path, 'scraper.rb'), 'w') do |f|
        f << <<-EOF
require 'scraperwiki'
require "open-uri"

puts "Running scraper"
ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer", "time" => Time.now})
        EOF
      end
      Morph::Runner.new(run).go {}
      run.reload
      expect(run.status_code).to eq 0
      expect(run.database.no_rows).to eq 1
    end

    it 'should magically handle a sidekiq queue restart' do
      owner = User.create(nickname: 'mlandauer')
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      FileUtils.mkdir_p(run.repo_path)
      File.open(File.join(run.repo_path, 'scraper.rb'), 'w') do |f|
        f << %q(
require 'scraperwiki'

puts "Started!"
ScraperWiki.save_sqlite(["state"], {"state" => "started"})
(1..10).each do |i|
  puts "#{i}..."
  sleep 0.1
end
puts "Finished!"
ScraperWiki.save_sqlite(["state"], {"state" => "finished"})
        )
      end
      logs = []

      runner = Morph::Runner.new(run)
      running_count = Morph::DockerUtils.running_containers.count
      container_count = Morph::DockerUtils.stopped_containers.count
      expect {runner.go_with_logging do |s, c|
        logs << c
        if c.include? "2..."
          raise Sidekiq::Shutdown
        end
      end}.to raise_error(Sidekiq::Shutdown)
      expect(logs.join).to eq [
        "Injecting configuration and compiling...\n",
        "Injecting scraper and running...\n",
        "Started!\n",
        "1...\n",
        "2...\n"
      ].join
      run.reload
      expect(run).to be_running
      # We expect the container to still be running
      expect(Morph::DockerUtils.running_containers.count)
        .to eq (running_count + 1)
      expect(run.database.first_ten_rows).to eq []

      # Now, we simulate the queue restarting the job
      started_at = run.started_at
      logs = []
      runner.go do |s, c|
        logs << c
      end
      expect(logs.join).to eq [
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
        { 'state' => 'started' }, { 'state' => 'finished' }]
    end

    it 'should handle restarting from a stopped container' do
      owner = User.create(nickname: 'mlandauer')
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      FileUtils.mkdir_p(run.repo_path)
      File.open(File.join(run.repo_path, 'scraper.rb'), 'w') do |f|
        f << %q(
require 'scraperwiki'

puts "Started!"
ScraperWiki.save_sqlite(["state"], {"state" => "started"})
(1..10).each do |i|
  puts "#{i}..."
  sleep 0.1
end
puts "Finished!"
ScraperWiki.save_sqlite(["state"], {"state" => "finished"})
        )
      end
      logs = []

      runner = Morph::Runner.new(run)
      running_count = Morph::DockerUtils.running_containers.count
      container_count = Morph::DockerUtils.stopped_containers.count
      expect {runner.go do |s, c|
        logs << c
        if c.include? "2..."
          raise Sidekiq::Shutdown
        end
      end}.to raise_error(Sidekiq::Shutdown)
      expect(logs.join).to eq [
        "Injecting configuration and compiling...\n",
        "Injecting scraper and running...\n",
        "Started!\n",
        "1...\n",
        "2...\n"
      ].join
      run.reload
      expect(run).to be_running
      # We expect the container to still be running
      expect(Morph::DockerUtils.running_containers.count)
        .to eq (running_count + 1)
      expect(run.database.first_ten_rows).to eq []

      # Wait until container is stopped
      sleep 2

      # Now, we simulate the queue restarting the job
      started_at = run.started_at
      logs = []
      runner.go do |s, c|
        logs << c
        #puts c
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
        { 'state' => 'started' }, { 'state' => 'finished' }]
    end

  end

  # TODO: Test that we can stop the compile stage
  describe ".stop!", docker: true do
    it 'should be able to stop a scraper running in a continuous loop' do
      owner = User.create(nickname: 'mlandauer')
      run = Run.create(owner: owner)
      FileUtils.rm_rf(run.data_path)
      FileUtils.rm_rf(run.repo_path)
      FileUtils.mkdir_p(run.repo_path)
      File.open(File.join(run.repo_path, 'scraper.rb'), 'w') do |f|
        f << %q(
require 'scraperwiki'

puts "Started!"
ScraperWiki.save_sqlite(["state"], {"state" => "started"})
(1..50).each do |i|
  puts "#{i}..."
  sleep 0.1
end
puts "Finished!"
ScraperWiki.save_sqlite(["state"], {"state" => "finished"})
        )
      end
      logs = []

      runner = Morph::Runner.new(run)
      container_count = Morph::DockerUtils.stopped_containers.count
      runner.go do |s, c|
        logs << c
        if c.include? "2..."
          # Putting the stop code in another thread (which is essentially
          # similar to how it works on morph.io for real)
          # If we don't do this we get a "Closed stream (IOError)" which I
          # haven't yet been able to figure out the origins of
          Thread.new { runner.stop! }
        end
      end
      expect(logs.join.include?("2...") || logs.join.include?("3...")).to eq true
      expect(Morph::DockerUtils.stopped_containers.count).to eq container_count
      expect(run.database.first_ten_rows).to eq [{ 'state' => 'started' }]
      expect(run.status_code).to eq 137
    end
  end

  describe '.add_config_defaults_to_directory' do
    before(:each) { FileUtils.mkdir('test') }
    after(:each) { FileUtils.rm_rf('test') }

    context 'a perl scraper' do
      before(:each) { FileUtils.touch('test/scraper.pl') }

      it do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory('test', dir)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', 'Procfile', 'app.psgi', 'cpanfile', 'scraper.pl']
          perl = Morph::Language.new(:perl)
          expect(File.read(File.join(dir, 'Procfile'))).to eq perl.procfile
          expect(File.read(File.join(dir, 'app.psgi')))
            .to eq File.read(perl.default_config_file_path('app.psgi'))
          expect(File.read(File.join(dir, 'cpanfile')))
            .to eq File.read(perl.default_config_file_path('cpanfile'))
        end
      end
    end

    context 'a ruby scraper' do
      before(:each) { FileUtils.touch('test/scraper.rb') }

      context 'user tries to override Procfile' do
        before :each do
          File.open('test/Procfile', 'w') { |f| f << 'scraper: some override' }
          FileUtils.touch('test/Gemfile')
          FileUtils.touch('test/Gemfile.lock')
        end

        it 'should always use the template Procfile' do
          Dir.mktmpdir do |dir|
            Morph::Runner.add_config_defaults_to_directory('test', dir)
            expect(Dir.entries(dir).sort).to eq [
              '.', '..', 'Gemfile', 'Gemfile.lock', 'Procfile', 'scraper.rb']
            expect(File.read(File.join(dir, 'Gemfile'))).to eq ''
            expect(File.read(File.join(dir, 'Gemfile.lock'))).to eq ''
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, 'Procfile'))).to eq ruby.procfile
          end
        end
      end

      context 'user supplies Gemfile and Gemfile.lock' do
        before :each do
          FileUtils.touch('test/Gemfile')
          FileUtils.touch('test/Gemfile.lock')
        end

        it 'should only provide a template Procfile' do
          Dir.mktmpdir do |dir|
            Morph::Runner.add_config_defaults_to_directory('test', dir)
            expect(Dir.entries(dir).sort).to eq [
              '.', '..', 'Gemfile', 'Gemfile.lock', 'Procfile', 'scraper.rb']
            expect(File.read(File.join(dir, 'Gemfile'))).to eq ''
            expect(File.read(File.join(dir, 'Gemfile.lock'))).to eq ''
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, 'Procfile'))).to eq ruby.procfile
          end
        end
      end

      context 'user does not supply Gemfile or Gemfile.lock' do
        it 'should provide a template Gemfile, Gemfile.lock and Procfile' do
          Dir.mktmpdir do |dir|
            Morph::Runner.add_config_defaults_to_directory('test', dir)
            expect(Dir.entries(dir).sort).to eq [
              '.', '..', 'Gemfile', 'Gemfile.lock', 'Procfile', 'scraper.rb']
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, 'Gemfile')))
              .to eq File.read(ruby.default_config_file_path('Gemfile'))
            expect(File.read(File.join(dir, 'Gemfile.lock')))
              .to eq File.read(ruby.default_config_file_path('Gemfile.lock'))
            expect(File.read(File.join(dir, 'Procfile'))).to eq ruby.procfile
          end
        end
      end

      context 'user supplies Gemfile but no Gemfile.lock' do
        before :each do
          FileUtils.touch('test/Gemfile')
        end

        it 'should not try to use the template Gemfile.lock' do
          Dir.mktmpdir do |dir|
            Morph::Runner.add_config_defaults_to_directory('test', dir)
            expect(Dir.entries(dir).sort).to eq [
              '.', '..', 'Gemfile', 'Procfile', 'scraper.rb']
            expect(File.read(File.join(dir, 'Gemfile'))).to eq ''
            ruby = Morph::Language.new(:ruby)
            expect(File.read(File.join(dir, 'Procfile'))).to eq ruby.procfile
          end
        end
      end
    end
  end

  describe '.remove_hidden_directories' do
    context 'a set of files' do
      before :each do
        FileUtils.mkdir_p('test/foo')
        FileUtils.mkdir_p('test/.bar')
        FileUtils.touch('test/.a_dot_file.cfg')
        FileUtils.touch('test/.bar/wibble.txt')
        FileUtils.touch('test/one.txt')
        FileUtils.touch('test/Procfile')
        FileUtils.touch('test/two.txt')
        FileUtils.touch('test/foo/three.txt')
        FileUtils.touch('test/Gemfile')
        FileUtils.touch('test/Gemfile.lock')
        FileUtils.touch('test/scraper.rb')
        FileUtils.ln_s('scraper.rb', 'test/link.rb')
      end

      after :each do
        FileUtils.rm_rf('test')
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents('test', dir)
          Morph::Runner.remove_hidden_directories(dir)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', '.a_dot_file.cfg', 'Gemfile', 'Gemfile.lock',
            'Procfile', 'foo', 'link.rb', 'one.txt', 'scraper.rb', 'two.txt']
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

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents('test', dir)
          Morph::Runner.remove_hidden_directories(dir)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', 'Gemfile', 'Gemfile.lock', 'foo', 'one.txt',
            'scraper.rb']
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

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents('test', dir)
          Morph::Runner.remove_hidden_directories(dir)
          expect(Dir.entries(dir).sort).to eq [
            '.', '..', 'Procfile', 'scraper.rb']
        end
      end
    end
  end
end
