# typed: false
# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

describe "User" do
  describe "abilities" do
    subject(:ability) { Ability.new(user) }

    let(:user) { nil }
    let(:scraper) do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create(:scraper)
      end
    end
    let(:organization) { create(:organization) }
    let(:other_user) { create(:user) }

    context "when an unauthenticated user" do
      # Scraper
      # Can
      it { is_expected.to be_able_to(:index, Scraper) }
      it { is_expected.to be_able_to(:running, Scraper) }
      it { is_expected.to be_able_to(:show, scraper) }
      it { is_expected.to be_able_to(:watchers, scraper) }
      it { is_expected.to be_able_to(:history, scraper) }

      # Can not
      it { is_expected.not_to be_able_to(:new, Scraper) }
      it { is_expected.not_to be_able_to(:create, Scraper) }
      it { is_expected.not_to be_able_to(:github, Scraper) }
      it { is_expected.not_to be_able_to(:github_form, Scraper) }
      it { is_expected.not_to be_able_to(:create_github, Scraper) }

      it { is_expected.not_to be_able_to(:settings, scraper) }
      it { is_expected.not_to be_able_to(:destroy, scraper) }
      it { is_expected.not_to be_able_to(:update, scraper) }
      it { is_expected.not_to be_able_to(:run, scraper) }
      it { is_expected.not_to be_able_to(:stop, scraper) }
      it { is_expected.not_to be_able_to(:clear, scraper) }
      it { is_expected.not_to be_able_to(:watch, scraper) }

      # Organization
      # Can
      it { is_expected.to be_able_to(:show, organization) }

      # Can not
      it { is_expected.not_to be_able_to(:settings, organization) }
      it { is_expected.not_to be_able_to(:settings_redirect, organization) }
      it { is_expected.not_to be_able_to(:reset_key, organization) }
      it { is_expected.not_to be_able_to(:watch, organization) }

      # User
      # Can
      it { is_expected.to be_able_to(:index, User) }
      it { is_expected.to be_able_to(:stats, User) }
      it { is_expected.to be_able_to(:watching, other_user) }
      it { is_expected.to be_able_to(:show, other_user) }

      # Can not
      it { is_expected.not_to be_able_to(:settings, other_user) }
      it { is_expected.not_to be_able_to(:settings_redirect, other_user) }
      it { is_expected.not_to be_able_to(:reset_key, other_user) }
      it { is_expected.not_to be_able_to(:watch, other_user) }
    end
  end
end
