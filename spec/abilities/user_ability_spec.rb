# typed: false
# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

describe "User" do
  describe "UserAbility" do
    subject(:ability) { UserAbility.new(user) }

    let(:user) { nil }
    let(:scraper) do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create(:scraper)
      end
    end
    let(:organization) { create(:organization) }
    let(:other_user) { create(:user) }

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
end
