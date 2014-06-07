require 'spec_helper'

describe Morph::ContainerCompiler do
  context "a set of files" do
    before :each do
      FileUtils.mkdir_p("test/foo")
      FileUtils.touch("test/one.txt")
      FileUtils.touch("test/Procfile")
      FileUtils.touch("test/two.txt")
      FileUtils.touch("test/foo/three.txt")
      FileUtils.touch("test/Gemfile")
      FileUtils.touch("test/Gemfile.lock")
    end

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".all_hash" do
      it {Morph::ContainerCompiler.all_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "Procfile" => "",
        "foo/three.txt" => "", "one.txt" => "", "two.txt" => ""}}
    end

    describe ".all_config_hash" do
      it {Morph::ContainerCompiler.all_config_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "Procfile" => ""}}
    end

    describe ".all_run_hash" do
      it {Morph::ContainerCompiler.all_run_hash("test").should == {
        "foo/three.txt" => "", "one.txt" => "", "two.txt" => ""}}
    end
  end

  context "another set of files" do
    before :each do
      FileUtils.mkdir_p("test/foo")
      FileUtils.touch("test/one.txt")
      FileUtils.touch("test/foo/three.txt")
      FileUtils.touch("test/Gemfile")
      FileUtils.touch("test/Gemfile.lock")
    end

    after :each do
      FileUtils.rm_rf("test")
    end

    describe ".all_hash" do
      it {Morph::ContainerCompiler.all_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => "", "foo/three.txt" => "", "one.txt" => ""
      }}
    end

    describe ".all_config_hash" do
      it {Morph::ContainerCompiler.all_config_hash("test").should == {
        "Gemfile" => "", "Gemfile.lock" => ""}}
    end

    describe ".all_run_hash" do
      it {Morph::ContainerCompiler.all_run_hash("test").should == {
        "foo/three.txt" => "", "one.txt" => ""}}
    end
  end
end
