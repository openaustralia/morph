require 'spec_helper'

describe Morph::DockerRunner do
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

    describe ".add_config_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", ".a_dot_file.cfg", ".bar", "Gemfile", "Gemfile.lock", "Procfile", "foo", "link.rb", "one.txt", "scraper.rb", "two.txt"]
          Dir.entries(File.join(dir, ".bar")).sort.should == [".", "..", "wibble.txt"]
          Dir.entries(File.join(dir, "foo")).sort.should == [".", "..", "three.txt"]
          File.read(File.join(dir, ".a_dot_file.cfg")).should == ""
          File.read(File.join(dir, ".bar", "wibble.txt")).should == ""
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
          File.read(File.join(dir, "foo", "three.txt")).should == ""
          File.read(File.join(dir, "link.rb")).should == ""
          File.read(File.join(dir, "one.txt")).should == ""
          File.read(File.join(dir, "scraper.rb")).should == ""
          File.read(File.join(dir, "two.txt")).should == ""
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

    describe ".add_config_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "foo", "one.txt", "scraper.rb"]
          Dir.entries(File.join(dir, "foo")).sort.should == [".", "..", "three.txt"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
          File.read(File.join(dir, "foo", "three.txt")).should == ""
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

    describe ".add_config_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "scraper.rb"]
          ruby = Morph::Language.new(:ruby)
          File.read(File.join(dir, "Gemfile")).should == File.read(ruby.default_config_file_path("Gemfile"))
          File.read(File.join(dir, "Gemfile.lock")).should == File.read(ruby.default_config_file_path("Gemfile.lock"))
          File.read(File.join(dir, "Procfile")).should == File.read(ruby.default_config_file_path("Procfile"))
          File.read(File.join(dir, "scraper.rb")).should == ""
        end
      end
    end
  end
end
