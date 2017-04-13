require 'spec_helper'

describe Run do
  describe "#wall_time" do
    context "run with a start and end 1 minute apart" do
      let(:run) { Run.new(id: 1, started_at: 5.minutes.ago, finished_at: 4.minutes.ago)}
      it { expect(run.wall_time).to be_within(0.1).of(60) }
    end

    context "run started but not finished" do
      let(:run) { Run.new(id: 1, started_at: 5.minutes.ago)}
      it { expect(run.wall_time).to eq 0 }
    end

    context "run queued but not started" do
      let(:run) { Run.new(id: 1)}
      it { expect(run.wall_time).to eq 0 }
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

  describe '#env_variables' do
    context 'has scraper' do
      let(:variable1) { mock_model(Variable, name: 'FOO', value: 'bar')}
      let(:variable2) { mock_model(Variable, name: 'WIBBLE', value: 'wobble')}
      let(:scraper) { mock_model(Scraper, variables: [variable1, variable2]) }
      let(:run) { Run.new(scraper: scraper) }
      it "should return all the variables" do
        expect(run.env_variables).to eq({'FOO' => 'bar', 'WIBBLE' => 'wobble'})
      end
    end

    context 'does not have scraper' do
      let(:run) { Run.new }
      it { expect(run.env_variables).to eq({}) }
    end
  end

  describe "#finished!" do
    let(:scraper) { mock_model(Scraper, update_sqlite_db_size: true, reindex: true, reload: true) }
    let(:run) { Run.new(scraper: scraper) }
    it "should call relevant methods on the scraper" do
      expect(scraper).to receive(:deliver_webhooks).with(run)
      run.finished!
    end
  end

  describe '#metric' do
    it 'is present after creation' do
      run = Run.create!
      expect(run.metric).to be_present
    end
  end
end
