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

      it do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "scraper.rb"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end

    context "another set of files" do
      before :each do
        FileUtils.touch("test/Gemfile")
        FileUtils.touch("test/Gemfile.lock")
      end

      it do
        Dir.mktmpdir do |dir|
          Morph::Runner.add_config_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile", "scraper.rb"]
          File.read(File.join(dir, "Gemfile")).should == ""
          File.read(File.join(dir, "Gemfile.lock")).should == ""
          File.read(File.join(dir, "Procfile")).should == File.read(Morph::Language.new(:ruby).default_config_file_path("Procfile"))
        end
      end
    end
  end
end
