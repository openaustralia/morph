# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Run do
  let(:user) { create(:user) }

  describe "#wall_time" do
    context "with run with a start and end 1 minute apart" do
      let(:run) { described_class.new(id: 1, started_at: 5.minutes.ago, finished_at: 4.minutes.ago) }

      it { expect(run.wall_time).to be_within(0.1).of(60) }
    end

    context "when run started but not finished" do
      let(:run) { described_class.new(id: 1, started_at: 5.minutes.ago) }

      it { expect(run.wall_time).to eq 0 }
    end

    context "when run queued but not started" do
      let(:run) { described_class.new(id: 1) }

      it { expect(run.wall_time).to eq 0 }
    end
  end

  describe "#finished_recently?" do
    context "when has never run" do
      let(:run) { described_class.new(finished_at: nil) }

      it { expect(run).not_to be_finished_recently }
    end

    context "when last finished 2 days ago" do
      let(:run) { described_class.new(finished_at: 2.days.ago) }

      it { expect(run).not_to be_finished_recently }
    end

    context "when last finished 2 hours ago" do
      let(:run) { described_class.new(finished_at: 2.hours.ago) }

      it { expect(run).to be_finished_recently }
    end
  end

  describe "#env_variables" do
    context "when has scraper" do
      let(:variable1) { mock_model(Variable, name: "FOO", value: "bar") }
      let(:variable2) { mock_model(Variable, name: "WIBBLE", value: "wobble") }
      let(:scraper) { mock_model(Scraper, variables: [variable1, variable2]) }
      let(:run) { described_class.new(scraper: scraper) }

      it "returns all the variables" do
        expect(run.env_variables).to eq("FOO" => "bar", "WIBBLE" => "wobble")
      end
    end

    context "when does not have scraper" do
      let(:run) { described_class.new }

      it { expect(run.env_variables).to eq({}) }
    end
  end

  describe "#finished!" do
    let(:scraper) { mock_model(Scraper, update_sqlite_db_size: true, reindex: true, reload: true, deliver_webhooks: nil) }
    let(:run) { described_class.new(scraper: scraper) }

    it "calls relevant methods on the scraper" do
      run.finished!
      expect(scraper).to have_received(:deliver_webhooks).with(run)
    end
  end

  describe "#metric" do
    it "is present after creation" do
      run = described_class.create!(owner: user)
      expect(run.metric).to be_present
    end
  end

  describe "#destroy" do
    context "with more than one metric for a single run" do
      let(:run) { described_class.create!(owner: user) }

      before do
        2.times { Metric.create!(run: run) }
      end

      it "does not raise an error" do
        expect do
          run.destroy
        end.to change(described_class, :count).by(-1)
      end
    end
  end
end
