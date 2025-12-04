# typed: false
# frozen_string_literal: true

# == Schema Information
#
# Table name: runs
#
#  id                    :integer          not null, primary key
#  auto                  :boolean          default(FALSE), not null
#  connection_logs_count :integer
#  docker_image          :string(255)
#  finished_at           :datetime
#  git_revision          :string(255)
#  ip_address            :string(255)
#  queued_at             :datetime
#  records_added         :integer
#  records_changed       :integer
#  records_removed       :integer
#  records_unchanged     :integer
#  started_at            :datetime
#  status_code           :integer
#  tables_added          :integer
#  tables_changed        :integer
#  tables_removed        :integer
#  tables_unchanged      :integer
#  wall_time             :float(24)        default(0.0), not null
#  created_at            :datetime
#  updated_at            :datetime
#  owner_id              :integer          not null
#  scraper_id            :integer
#
# Indexes
#
#  index_runs_on_created_at                                  (created_at)
#  index_runs_on_docker_image                                (docker_image)
#  index_runs_on_finished_at                                 (finished_at)
#  index_runs_on_ip_address                                  (ip_address)
#  index_runs_on_owner_id                                    (owner_id)
#  index_runs_on_scraper_id                                  (scraper_id)
#  index_runs_on_scraper_id_and_status_code_and_finished_at  (scraper_id,status_code,finished_at)
#  index_runs_on_started_at                                  (started_at)
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#
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
