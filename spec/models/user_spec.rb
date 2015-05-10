require 'spec_helper'

describe User do
  let(:user) {User.new}

  context "user has no scrapers" do
    describe "#watched_successful_scrapers" do
      it{ expect(user.watched_successful_scrapers).to eq []}
    end

    describe "#watched_broken_scrapers" do
      it{ expect(user.watched_broken_scrapers).to eq []}
    end
  end

  context "user is watching one scraper and it ran successfully" do
    let(:scraper) {mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false)}
    before :each do
      expect(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it{ expect(user.watched_successful_scrapers).to eq [scraper]}
    end

    describe "#watched_broken_scrapers" do
      it{ expect(user.watched_broken_scrapers).to eq []}
    end
  end

  context "user is watching one scraper and it failed" do
    let(:scraper) {mock_model(Scraper, finished_successfully?: false, finished_with_errors?: true)}
    before :each do
      expect(user).to receive(:all_scrapers_watched).and_return([scraper])
    end

    describe "#watched_successful_scrapers" do
      it{ expect(user.watched_successful_scrapers).to eq []}
    end

    describe "#watched_broken_scrapers" do
      it{ expect(user.watched_broken_scrapers).to eq [scraper]}
    end
  end

  context "user is watching two scrapers, one failed and one ran successfully" do
    let(:scraper1) {mock_model(Scraper, finished_successfully?: false, finished_with_errors?: true)}
    let(:scraper2) {mock_model(Scraper, finished_successfully?: true, finished_with_errors?: false)}
    before :each do
      expect(user).to receive(:all_scrapers_watched).and_return([scraper1, scraper2])
    end

    describe "#watched_successful_scrapers" do
      it{ expect(user.watched_successful_scrapers).to eq [scraper2]}
    end

    describe "#watched_broken_scrapers" do
      it{ expect(user.watched_broken_scrapers).to eq [scraper1]}
    end
  end
end
