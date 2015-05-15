require 'spec_helper'

describe Morph::DockerRunner do
  describe ".fix_modification_times" do
    it do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "foo"))
        FileUtils.mkdir_p(File.join(dir, "bar"))
        FileUtils.touch(File.join(dir, "bar", "twist"))
        Morph::DockerRunner.fix_modification_times(dir)
        File.mtime(dir).should == Time.new(2000,1,1)
        File.mtime(File.join(dir, "foo")).should == Time.new(2000,1,1)
        File.mtime(File.join(dir, "bar")).should == Time.new(2000,1,1)
        File.mtime(File.join(dir, "bar", "twist")).should == Time.new(2000,1,1)
      end
    end
  end

  context "a set of files" do
    before :each do
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

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.write_all_run_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", ".a_dot_file.cfg", "foo", "link.rb", "one.txt", "scraper.rb", "two.txt"]
          Dir.entries(File.join(dir, "foo")).sort.should == [".", "..", "three.txt"]
          File.read(File.join(dir, ".a_dot_file.cfg")).should == ""
          File.read(File.join(dir, "foo/three.txt")).should == ""
          File.read(File.join(dir, "one.txt")).should == ""
          File.read(File.join(dir, "scraper.rb")).should == ""
          File.read(File.join(dir, "two.txt")).should == ""
          File.readlink(File.join(dir, "link.rb")).should == "scraper.rb"
        end
      end
    end
  end

  context "another set of files" do
    before :each do
      FileUtils.mkdir_p("test/foo")
      FileUtils.touch("test/one.txt")
      FileUtils.touch("test/foo/three.txt")
      FileUtils.touch("test/Gemfile")
      FileUtils.touch("test/Gemfile.lock")
      FileUtils.touch("test/scraper.rb")
    end

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.write_all_run_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "foo", "one.txt", "scraper.rb"]
          Dir.entries(File.join(dir, "foo")).sort.should == [".", "..", "three.txt"]
          File.read(File.join(dir, "foo/three.txt")).should == ""
          File.read(File.join(dir, "one.txt")).should == ""
          File.read(File.join(dir, "scraper.rb")).should == ""
        end
      end
    end
  end

  context "user tries to override Procfile" do
    before :each do
      FileUtils.mkdir_p("test")
      File.open("test/Procfile", "w") {|f| f << "scraper: some override"}
      FileUtils.touch("test/scraper.rb")
    end

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
          ruby = Morph::Language.new(:ruby)
          File.read(File.join(dir, "Gemfile")).should == File.read(ruby.default_config_file_path("Gemfile"))
          File.read(File.join(dir, "Gemfile.lock")).should == File.read(ruby.default_config_file_path("Gemfile.lock"))
          File.read(File.join(dir, "Procfile")).should == File.read(ruby.default_config_file_path("Procfile"))
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::DockerRunner.write_all_run_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "scraper.rb"]
          File.read(File.join(dir, "scraper.rb")).should == ""
        end
      end
    end
  end
end
