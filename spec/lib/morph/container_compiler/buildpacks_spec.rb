require 'spec_helper'

describe Morph::ContainerCompiler::Buildpacks do
  describe ".fix_modification_times" do
    it do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "foo"))
        FileUtils.mkdir_p(File.join(dir, "bar"))
        FileUtils.touch(File.join(dir, "bar", "twist"))
        Morph::ContainerCompiler::Buildpacks.fix_modification_times(dir)
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
    end

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".all_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "Procfile" => "",
        "foo/three.txt" => "", "one.txt" => "", "two.txt" => "", "scraper.rb" => "",
        ".a_dot_file.cfg" => ""}}
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
        "foo/three.txt" => "", "one.txt" => "", "two.txt" => "", "scraper.rb" => "",
        ".a_dot_file.cfg" => ""}}
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_run_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", ".a_dot_file.cfg", "foo", "one.txt", "scraper.rb", "two.txt"]
          Dir.entries(File.join(dir, "foo")).sort.should == [".", "..", "three.txt"]
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
        "Procfile"=> File.read("default_files/ruby/Procfile")}}
    end

    describe ".all_run_hash" do
      it {Morph::ContainerCompiler::Buildpacks.all_run_hash("test").should == {
        "foo/three.txt" => "", "one.txt" => "", "scraper.rb" => ""}}
    end

    describe ".write_all_config_with_defaults_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_config_with_defaults_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "Gemfile", "Gemfile.lock", "Procfile"]
          File.read(File.join(dir, "Procfile")).should == File.read("default_files/ruby/Procfile")
        end
      end
    end

    describe ".write_all_run_to_directory" do
      it do
        Dir.mktmpdir do |dir|
          Morph::ContainerCompiler::Buildpacks.write_all_run_to_directory("test", dir)
          Dir.entries(dir).sort.should == [".", "..", "foo", "one.txt", "scraper.rb"]
          Dir.entries(File.join(dir, "foo")).sort.should == [".", "..", "three.txt"]
        end
      end
    end
  end
end
