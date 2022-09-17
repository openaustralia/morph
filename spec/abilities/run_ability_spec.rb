# typed: false
# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

describe "User" do
  describe "RunAbility" do
    subject(:ability) { RunAbility.new(user) }

    let(:user) { nil }
    let(:scraper) do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create(:scraper)
      end
    end
    let(:organization) { create(:organization) }
    let(:other_user) { create(:user) }

    context "when an unauthenticated user" do
      it { is_expected.not_to be_able_to(:create, Run) }
    end

    context "when a regular authenticated user" do
      let(:user) { create(:user) }

      it { is_expected.to be_able_to(:create, Run) }
    end

    context "when an admin" do
      let(:user) { create(:user, admin: true) }

      context "when the site is in read-only mode" do
        before do
          SiteSetting.read_only_mode = true
        end

        # Run
        it { is_expected.not_to be_able_to(:create, Run) }
      end
    end
  end
end
