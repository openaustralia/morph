# typed: false
# frozen_string_literal: true

require "spec_helper"

describe User do
  let(:user) { described_class.new }

  context "when user has no scrapers" do
    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [] }
    end
  end

  context "when user is watching one scraper and it ran successfully" do
    let(:scraper) { mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false, finished_recently?: true) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [scraper] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [] }
    end
  end

  context "when user is watching one scraper and it ran successfully but not recently" do
    let(:scraper) { mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false, finished_recently?: false) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [] }
    end
  end

  context "when user is watching one scraper and it failed" do
    let(:scraper) { mock_model(Scraper, finished_successfully?: false, finished_with_errors?: true, finished_recently?: true) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [scraper] }
    end
  end

  context "when user is watching two scrapers, one failed and one ran successfully" do
    let(:scraper1) { mock_model(Scraper, finished_successfully?: false, finished_with_errors?: true, finished_recently?: true) }
    let(:scraper2) { mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false, finished_recently?: true) }

    before do
      allow(user).to receive(:all_scrapers_watched).and_return([scraper1, scraper2])
    end

    describe "#watched_successful_scrapers" do
      it { expect(user.watched_successful_scrapers).to eq [scraper2] }
    end

    describe "#watched_broken_scrapers" do
      it { expect(user.watched_broken_scrapers).to eq [scraper1] }
    end
  end
end
