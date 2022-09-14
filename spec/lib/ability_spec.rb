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

    context "when an unauthenticated user" do
      # TODO: Fix things so that the pending tests pass

      # Can
      it { is_expected.to be_able_to(:index, Scraper) }
      it { is_expected.to be_able_to(:new, Scraper) }
      pending { is_expected.to be_able_to(:running, Scraper) }
      it { is_expected.to be_able_to(:show, scraper) }
      it { is_expected.to be_able_to(:watchers, scraper) }
      pending { is_expected.to be_able_to(:history, scraper) }

      # Can not
      pending { is_expected.not_to be_able_to(:create, Scraper) }
      pending { is_expected.not_to be_able_to(:github, Scraper) }
      it { is_expected.not_to be_able_to(:github_form, Scraper) }
      pending { is_expected.not_to be_able_to(:create_github, Scraper) }

      it { is_expected.not_to be_able_to(:settings, scraper) }
      it { is_expected.not_to be_able_to(:destroy, scraper) }
      it { is_expected.not_to be_able_to(:update, scraper) }
      it { is_expected.not_to be_able_to(:run, scraper) }
      it { is_expected.not_to be_able_to(:stop, scraper) }
      it { is_expected.not_to be_able_to(:clear, scraper) }
      it { is_expected.not_to be_able_to(:watch, scraper) }
    end
  end
end
