require 'spec_helper'

describe Morph::DockerRunner do
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
end
