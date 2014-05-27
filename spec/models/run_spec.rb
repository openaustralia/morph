require 'spec_helper'

describe Run do
  describe "#wall_time" do
    context "run with a start and end 1 minute apart" do
      let(:run) { Run.new(id: 1, started_at: 5.minutes.ago, finished_at: 4.minutes.ago)}
      it { run.wall_time.should be_within(0.1).of(60) }
    end

    context "run started but not finished" do
      let(:run) { Run.new(id: 1, started_at: 5.minutes.ago)}
      it { run.wall_time.should == 0 }
    end

    context "run queued but not started" do
      let(:run) { Run.new(id: 1)}
      it { run.wall_time.should == 0 }
    end
  end

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

    describe ".all_paths" do
      it {Run.all_paths("test").should == ["Gemfile", "Gemfile.lock", "Procfile", "foo/three.txt", "one.txt", "two.txt"]}
    end

    describe ".all_config_paths" do
      it {Run.all_config_paths("test").should == ["Gemfile", "Gemfile.lock", "Procfile"]}
    end

    describe ".all_run_paths" do
      it {Run.all_run_paths("test").should == ["foo/three.txt", "one.txt", "two.txt"]}
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

    describe ".all_paths" do
      it {Run.all_paths("test").should == ["Gemfile", "Gemfile.lock", "foo/three.txt", "one.txt"]}
    end

    describe ".all_config_paths" do
      it {Run.all_config_paths("test").should == ["Gemfile", "Gemfile.lock"]}
    end

    describe ".all_run_paths" do
      it {Run.all_run_paths("test").should == ["foo/three.txt", "one.txt"]}
    end
  end
end
