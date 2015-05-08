require 'spec_helper'

describe User do
  describe "#successful_scrapers" do
    let(:user) {User.new}

    context "user has no scrapers" do
      it{ expect(user.successful_scrapers).to eq []}
    end

    context "user is watching one scraper and it ran successfully" do
      let(:scraper) {mock_model(Scraper, last_run_finished_successfully?: true)}
      before :each do
        expect(user).to receive(:all_scrapers_watched).and_return([scraper])
      end

      it{ expect(user.successful_scrapers).to eq [scraper]}
    end

    context "user is watching one scraper and it failed" do
      let(:scraper) {mock_model(Scraper, last_run_finished_successfully?: false)}
      before :each do
        expect(user).to receive(:all_scrapers_watched).and_return([scraper])
      end

      it{ expect(user.successful_scrapers).to eq []}
    end

    context "user is watching two scrapers, one failed and one ran successfully" do
      let(:scraper1) {mock_model(Scraper, last_run_finished_successfully?: false)}
      let(:scraper2) {mock_model(Scraper, last_run_finished_successfully?: true)}
      before :each do
        expect(user).to receive(:all_scrapers_watched).and_return([scraper1, scraper2])
      end

      it{ expect(user.successful_scrapers).to eq [scraper2]}
    end
  end
end
