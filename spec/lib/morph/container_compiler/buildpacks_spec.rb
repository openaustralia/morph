require 'spec_helper'

describe Morph::ContainerCompiler::Buildpacks do
  context "a set of files" do
    before :each do
      FileUtils.mkdir_p("test/foo")
      FileUtils.touch("test/one.txt")
      FileUtils.touch("test/Procfile")
      FileUtils.touch("test/two.txt")
      FileUtils.touch("test/foo/three.txt")
      FileUtils.touch("test/Gemfile")
      FileUtils.touch("test/Gemfile.lock")
      FileUtils.touch("test/scraper.rb")
    end

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".all_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "Procfile" => "",
        "foo/three.txt" => "", "one.txt" => "", "two.txt" => "", "scraper.rb" => ""}}
    end

    describe ".all_config_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_config_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "Procfile" => ""}}
    end

    describe ".all_config_hash_with_defaults" do
      it {Morph::ContainerCompiler::Buildpacks.all_config_hash_with_defaults("test").should == {"Gemfile"=>"", "Gemfile.lock"=>"", "Procfile"=>""}}
    end

    describe ".all_run_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_run_hash("test").should == {
        "foo/three.txt" => "", "one.txt" => "", "two.txt" => "", "scraper.rb" => ""}}
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_run_to_directory("test", dir)
          Dir.entries(dir).should == [".", "..", "foo", "one.txt", "scraper.rb", "two.txt"]
          Dir.entries(File.join(dir, "foo")).should == [".", "..", "three.txt"]
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

    describe ".all_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "foo/three.txt" => "", "one.txt" => "",
        "scraper.rb" => ""
      }}
    end

    describe ".all_config_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_config_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => ""}}
    end

    describe ".all_config_hash_with_defaults" do
      it {Morph::ContainerCompiler::Buildpacks.all_config_hash_with_defaults("test").should == {
        "Gemfile"=>"", "Gemfile.lock"=>"",
        "Procfile"=>"scraper: bundle exec ruby -r/usr/local/lib/prerun.rb scraper.rb\n"}}
    end

    describe ".all_run_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_run_hash("test").should == {
        "foo/three.txt" => "", "one.txt" => "", "scraper.rb" => ""}}
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
          File.read(File.join(dir, "Procfile")).should ==
            "scraper: bundle exec ruby -r/usr/local/lib/prerun.rb scraper.rb\n"
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_run_to_directory("test", dir)
          Dir.entries(dir).should == [".", "..", "foo", "one.txt", "scraper.rb"]
          Dir.entries(File.join(dir, "foo")).should == [".", "..", "three.txt"]
        end
      end
    end
  end
end
