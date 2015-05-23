require 'spec_helper'

describe Morph::Runner do
  describe ".add_config_defaults_to_directory" do
    before(:each) do
      FileUtils.mkdir("test")
      FileUtils.touch("test/scraper.rb")
    end
    after(:each) { FileUtils.rm_rf("test") }

    context "user tries to override Procfile" do
      before :each do
        File.open("test/Procfile", "w") {|f| f << "scraper: some override"}
        FileUtils.touch("test/Gemfile")
        FileUtils.touch("test/Gemfile.lock")
      end

      it "should always use the template Procfile" do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "scraper.rb"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end

    context "user supplies Gemfile and Gemfile.lock" do
      before :each do
        FileUtils.touch("test/Gemfile")
        FileUtils.touch("test/Gemfile.lock")
      end

      it "should only provide a template Procfile" do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "scraper.rb"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end

    context "user doesn't supply Gemfile or Gemfile.lock" do
      it "should provide a template Gemfile, Gemfile.lock and Procfile" do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "scraper.rb"]
          ruby = Morph::Language.new(:ruby)
          File.read(File.join(dir, "Gemfile")).should == File.read(ruby.default_config_file_path("Gemfile"))
          File.read(File.join(dir, "Gemfile.lock")).should == File.read(ruby.default_config_file_path("Gemfile.lock"))
          File.read(File.join(dir, "Procfile")).should == File.read(ruby.default_config_file_path("Procfile"))
        end
      end
    end

    context "user supplies Gemfile but no Gemfile.lock" do
      before :each do
        FileUtils.touch("test/Gemfile")
      end

      it "should not try to use the template Gemfile.lock" do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Procfile", "scraper.rb"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end
  end

  describe ".remove_hidden_directories" do
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

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents("test", dir)
          Morph::Runner.remove_hidden_directories(dir)
          Dir.entries(dir).sort.should == [".", "..", ".a_dot_file.cfg", "Gemfile", "Gemfile.lock", "Procfile", "foo", "link.rb", "one.txt", "scraper.rb", "two.txt"]
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

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents("test", dir)
          Morph::Runner.remove_hidden_directories(dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "foo", "one.txt", "scraper.rb"]
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

      it do
        Dir.mktmpdir do |dir|
          Morph::DockerUtils.copy_directory_contents("test", dir)
          Morph::Runner.remove_hidden_directories(dir)
          Dir.entries(dir).sort.should == [".", "..", "Procfile", "scraper.rb"]
        end
      end
    end
  end
end
