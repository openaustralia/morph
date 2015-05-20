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

  describe "#finished_recently?" do
    context "has never run" do
      let(:run) { Run.new(finished_at: nil) }
      it {expect(run.finished_recently?).to be_falsey}
    end

    context "last finished 2 days ago" do
      let(:run) { Run.new(finished_at: 2.days.ago) }
      it {expect(run.finished_recently?).to be_falsey}
    end

    context "last finished 2 hours ago" do
      let(:run) { Run.new(finished_at: 2.hours.ago) }
      it {expect(run.finished_recently?).to be_truthy}
    end
  end
end
