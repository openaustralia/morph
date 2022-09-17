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

    describe "user" do
      # :index, :watching, :stats
      context "when an unauthenticated user" do
        it { is_expected.to be_able_to(:index, User) }
        it { is_expected.to be_able_to(:stats, User) }
        it { is_expected.to be_able_to(:watching, other_user) }
      end

      context "when a regular authenticated user" do
        let(:user) { create(:user) }

        it { is_expected.to be_able_to(:index, User) }
        it { is_expected.to be_able_to(:stats, User) }
        it { is_expected.to be_able_to(:watching, other_user) }
      end
    end

    describe "site_setting" do
      context "when an unauthenticated user" do
        it { is_expected.not_to be_able_to(:toggle_read_only_mode, SiteSetting) }
        it { is_expected.not_to be_able_to(:update_maximum_concurrent_scrapers, SiteSetting) }
      end

      context "when a regular authenticated user" do
        let(:user) { create(:user) }

        it { is_expected.not_to be_able_to(:toggle_read_only_mode, SiteSetting) }
        it { is_expected.not_to be_able_to(:update_maximum_concurrent_scrapers, SiteSetting) }
      end

      context "when an admin" do
        let(:user) { create(:user, admin: true) }

        # Just checking for extra permissions an admin is expected to have
        it { is_expected.to be_able_to(:toggle_read_only_mode, SiteSetting) }
        it { is_expected.to be_able_to(:update_maximum_concurrent_scrapers, SiteSetting) }
      end
    end

    describe "run" do
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
end
