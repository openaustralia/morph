# typed: false
# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

describe "ScraperAbility" do
  subject(:ability) { ScraperAbility.new(user) }

  let(:user) { nil }
  let(:scraper) do
    VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
      create(:scraper)
    end
  end
  let(:private_scraper) do
    VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
      create(:scraper, private: true)
    end
  end
  let(:organization) { create(:organization) }

  context "when an unauthenticated user" do
    it { is_expected.to be_able_to(:index, Scraper) }
    it { is_expected.to be_able_to(:running, Scraper) }
    it { is_expected.to be_able_to(:show, scraper) }
    it { is_expected.not_to be_able_to(:show, private_scraper) }
    it { is_expected.to be_able_to(:watchers, scraper) }
    it { is_expected.not_to be_able_to(:watchers, private_scraper) }
    it { is_expected.to be_able_to(:history, scraper) }
    it { is_expected.not_to be_able_to(:history, private_scraper) }
    it { is_expected.not_to be_able_to(:data, scraper) }
    it { is_expected.not_to be_able_to(:data, private_scraper) }
    it { is_expected.not_to be_able_to(:new, Scraper) }
    it { is_expected.not_to be_able_to(:create, Scraper) }
    it { is_expected.not_to be_able_to(:github, Scraper) }
    it { is_expected.not_to be_able_to(:github_form, Scraper) }
    it { is_expected.not_to be_able_to(:create_github, Scraper) }
    it { is_expected.not_to be_able_to(:memory_setting, Scraper) }
    it { is_expected.not_to be_able_to(:edit, scraper) }
    it { is_expected.not_to be_able_to(:destroy, scraper) }
    it { is_expected.not_to be_able_to(:update, scraper) }
    it { is_expected.not_to be_able_to(:run, scraper) }
    it { is_expected.not_to be_able_to(:stop, scraper) }
    it { is_expected.not_to be_able_to(:clear, scraper) }
    it { is_expected.not_to be_able_to(:watch, scraper) }
  end

  context "when a regular authenticated user" do
    let(:user) { create(:user) }

    it { is_expected.to be_able_to(:index, Scraper) }
    it { is_expected.to be_able_to(:running, Scraper) }
    it { is_expected.to be_able_to(:show, scraper) }
    it { is_expected.not_to be_able_to(:show, private_scraper) }
    it { is_expected.to be_able_to(:watchers, scraper) }
    it { is_expected.not_to be_able_to(:watchers, private_scraper) }
    it { is_expected.to be_able_to(:history, scraper) }
    it { is_expected.not_to be_able_to(:history, private_scraper) }
    it { is_expected.to be_able_to(:new, Scraper) }
    it { is_expected.to be_able_to(:create, Scraper) }
    it { is_expected.to be_able_to(:github, Scraper) }
    it { is_expected.to be_able_to(:github_form, Scraper) }
    it { is_expected.to be_able_to(:create_github, Scraper) }
    it { is_expected.to be_able_to(:watch, scraper) }
    it { is_expected.not_to be_able_to(:watch, private_scraper) }
    it { is_expected.to be_able_to(:data, scraper) }
    it { is_expected.not_to be_able_to(:data, private_scraper) }
    it { is_expected.not_to be_able_to(:memory_setting, Scraper) }
    it { is_expected.not_to be_able_to(:edit, scraper) }
    it { is_expected.not_to be_able_to(:destroy, scraper) }
    it { is_expected.not_to be_able_to(:update, scraper) }
    it { is_expected.not_to be_able_to(:run, scraper) }
    it { is_expected.not_to be_able_to(:stop, scraper) }
    it { is_expected.not_to be_able_to(:clear, scraper) }

    context "when scraper is owner by the user" do
      before do
        scraper.update(owner: user)
      end

      it { is_expected.to be_able_to(:edit, scraper) }
      it { is_expected.to be_able_to(:destroy, scraper) }
      it { is_expected.to be_able_to(:update, scraper) }
      it { is_expected.to be_able_to(:run, scraper) }
      it { is_expected.to be_able_to(:stop, scraper) }
      it { is_expected.to be_able_to(:clear, scraper) }
      it { is_expected.to be_able_to(:watch, scraper) }
    end

    context "when private scraper is owner by the user" do
      before do
        private_scraper.update(owner: user)
      end

      it { is_expected.to be_able_to(:show, private_scraper) }
      it { is_expected.to be_able_to(:watchers, private_scraper) }
      it { is_expected.to be_able_to(:history, private_scraper) }
      it { is_expected.to be_able_to(:edit, private_scraper) }
      it { is_expected.to be_able_to(:destroy, private_scraper) }
      it { is_expected.to be_able_to(:update, private_scraper) }
      it { is_expected.to be_able_to(:run, private_scraper) }
      it { is_expected.to be_able_to(:stop, private_scraper) }
      it { is_expected.to be_able_to(:clear, private_scraper) }
      it { is_expected.to be_able_to(:watch, private_scraper) }
      it { is_expected.to be_able_to(:data, private_scraper) }
    end

    context "when scraper is owned by an organization the user is a member of" do
      before do
        scraper.update(owner: organization)
        create(:organizations_user, organization: organization, user: user)
      end

      it { is_expected.to be_able_to(:edit, scraper) }
      it { is_expected.to be_able_to(:destroy, scraper) }
      it { is_expected.to be_able_to(:update, scraper) }
      it { is_expected.to be_able_to(:run, scraper) }
      it { is_expected.to be_able_to(:stop, scraper) }
      it { is_expected.to be_able_to(:clear, scraper) }
      it { is_expected.to be_able_to(:watch, scraper) }
    end

    context "when private scraper is owned by an organization the user is a member of" do
      before do
        private_scraper.update(owner: organization)
        create(:organizations_user, organization: organization, user: user)
      end

      it { is_expected.to be_able_to(:show, private_scraper) }
      it { is_expected.to be_able_to(:watchers, private_scraper) }
      it { is_expected.to be_able_to(:history, private_scraper) }
      it { is_expected.to be_able_to(:edit, private_scraper) }
      it { is_expected.to be_able_to(:destroy, private_scraper) }
      it { is_expected.to be_able_to(:update, private_scraper) }
      it { is_expected.to be_able_to(:run, private_scraper) }
      it { is_expected.to be_able_to(:stop, private_scraper) }
      it { is_expected.to be_able_to(:clear, private_scraper) }
      it { is_expected.to be_able_to(:watch, private_scraper) }
      it { is_expected.to be_able_to(:data, private_scraper) }
    end
  end

  context "when an admin" do
    let(:user) { create(:user, admin: true) }

    # Just checking for extra permissions an admin is expected to have
    it { is_expected.to be_able_to(:memory_setting, Scraper) }

    context "when the site is in read-only mode" do
      before do
        SiteSetting.read_only_mode = true
      end

      it { is_expected.not_to be_able_to(:new, Scraper) }
      it { is_expected.not_to be_able_to(:create, Scraper) }
      it { is_expected.not_to be_able_to(:github, Scraper) }
      it { is_expected.not_to be_able_to(:github_form, Scraper) }
      it { is_expected.not_to be_able_to(:create_github, Scraper) }
      it { is_expected.not_to be_able_to(:watch, scraper) }

      context "when scraper is owner by the user" do
        before do
          scraper.update(owner: user)
        end

        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
        it { is_expected.not_to be_able_to(:run, scraper) }
        it { is_expected.not_to be_able_to(:stop, scraper) }
        it { is_expected.not_to be_able_to(:clear, scraper) }
        it { is_expected.not_to be_able_to(:watch, scraper) }
      end

      context "when scraper is owned by an organization the user is a member of" do
        before do
          scraper.update(owner: organization)
          create(:organizations_user, organization: organization, user: user)
        end

        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
        it { is_expected.not_to be_able_to(:run, scraper) }
        it { is_expected.not_to be_able_to(:stop, scraper) }
        it { is_expected.not_to be_able_to(:clear, scraper) }
        it { is_expected.not_to be_able_to(:watch, scraper) }
      end
    end
  end
end
