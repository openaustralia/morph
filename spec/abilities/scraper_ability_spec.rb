# typed: false
# frozen_string_literal: true

require "spec_helper"
require "cancan/matchers"

describe "ScraperAbility" do
  subject(:ability) { ScraperAbility.new(user) }

  context "when an unauthenticated user" do
    context "with a public scraper" do
      let(:user) { nil }
      let(:scraper) { create(:scraper) }

      it { is_expected.to be_able_to(:index, Scraper) }
      it { is_expected.to be_able_to(:show, scraper) }
      it { is_expected.not_to be_able_to(:data, scraper) }
      it { is_expected.not_to be_able_to(:new, Scraper) }
      it { is_expected.not_to be_able_to(:create, Scraper) }
      it { is_expected.not_to be_able_to(:create_private, Scraper) }
      it { is_expected.not_to be_able_to(:memory_setting, Scraper) }
      it { is_expected.not_to be_able_to(:edit, scraper) }
      it { is_expected.not_to be_able_to(:destroy, scraper) }
      it { is_expected.not_to be_able_to(:update, scraper) }
      it { is_expected.not_to be_able_to(:watch, scraper) }
    end

    context "with a private scraper" do
      let(:user) { nil }
      let(:scraper) { create(:scraper, private: true) }

      it { is_expected.not_to be_able_to(:show, scraper) }
      it { is_expected.not_to be_able_to(:data, scraper) }
      it { is_expected.not_to be_able_to(:edit, scraper) }
      it { is_expected.not_to be_able_to(:destroy, scraper) }
      it { is_expected.not_to be_able_to(:update, scraper) }
      it { is_expected.not_to be_able_to(:watch, scraper) }
    end
  end

  context "when a regular authenticated user" do
    context "with a public scraper" do
      context "when scraper is owned by a different user" do
        let(:user) { create(:user) }
        let(:scraper) { create(:scraper) }

        it { is_expected.to be_able_to(:index, Scraper) }
        it { is_expected.to be_able_to(:show, scraper) }
        it { is_expected.to be_able_to(:new, Scraper) }
        it { is_expected.to be_able_to(:create, Scraper) }
        it { is_expected.not_to be_able_to(:create_private, Scraper) }
        it { is_expected.to be_able_to(:watch, scraper) }
        it { is_expected.to be_able_to(:data, scraper) }
        it { is_expected.not_to be_able_to(:memory_setting, Scraper) }
        it { is_expected.not_to be_able_to(:edit, scraper) }
        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
      end

      context "when scraper is owned by the user" do
        let(:user) { create(:user) }
        let(:scraper) { create(:scraper, owner: user) }

        it { is_expected.to be_able_to(:edit, scraper) }
        it { is_expected.to be_able_to(:destroy, scraper) }
        it { is_expected.to be_able_to(:update, scraper) }
        it { is_expected.to be_able_to(:watch, scraper) }
      end

      context "when a scraper is owned by an organization" do
        let(:user) { create(:user) }
        let(:organization) { create(:organization) }
        let(:scraper) { create(:scraper, owner: organization) }

        context "when the user is not a member of the organization" do
          it { is_expected.not_to be_able_to(:edit, scraper) }
          it { is_expected.not_to be_able_to(:destroy, scraper) }
          it { is_expected.not_to be_able_to(:update, scraper) }
          it { is_expected.to be_able_to(:watch, scraper) }
        end

        context "when the user is a member of the organization" do
          before do
            create(:organizations_user, organization: organization, user: user)
          end

          it { is_expected.to be_able_to(:edit, scraper) }
          it { is_expected.to be_able_to(:destroy, scraper) }
          it { is_expected.to be_able_to(:update, scraper) }
          it { is_expected.to be_able_to(:watch, scraper) }
        end
      end
    end

    context "with a private scraper" do
      context "when user is not a collaborator on the scraper" do
        let(:user) { create(:user) }
        let(:scraper) { create(:scraper, private: true) }

        it { is_expected.not_to be_able_to(:show, scraper) }
        it { is_expected.not_to be_able_to(:watch, scraper) }
        it { is_expected.not_to be_able_to(:data, scraper) }
        it { is_expected.not_to be_able_to(:edit, scraper) }
        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
      end

      context "when user is a collaborator with no permissions on the scraper" do
        let(:user) { create(:user) }
        let(:scraper) { create(:scraper, private: true) }

        before do
          create(:collaboration, scraper: scraper, owner: user)
        end

        it { is_expected.not_to be_able_to(:show, scraper) }
        it { is_expected.not_to be_able_to(:edit, scraper) }
        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
        it { is_expected.not_to be_able_to(:watch, scraper) }
        it { is_expected.not_to be_able_to(:data, scraper) }
      end

      context "when user is a collaborator with read permissions only on the scraper" do
        let(:user) { create(:user) }
        let(:scraper) { create(:scraper, private: true) }

        before do
          create(:collaboration, scraper: scraper, owner: user, pull: true)
        end

        it { is_expected.to be_able_to(:show, scraper) }
        it { is_expected.not_to be_able_to(:edit, scraper) }
        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
        it { is_expected.to be_able_to(:watch, scraper) }
        it { is_expected.to be_able_to(:data, scraper) }
      end

      context "when user is a collaborator with admin permissions on the scraper" do
        let(:user) { create(:user) }
        let(:scraper) { create(:scraper, private: true) }

        before do
          create(:collaboration, scraper: scraper, owner: user, pull: true, admin: true)
        end

        it { is_expected.to be_able_to(:show, scraper) }
        it { is_expected.to be_able_to(:edit, scraper) }
        it { is_expected.to be_able_to(:destroy, scraper) }
        it { is_expected.to be_able_to(:update, scraper) }
        it { is_expected.to be_able_to(:watch, scraper) }
        it { is_expected.to be_able_to(:data, scraper) }
      end

      context "when scraper is owned by an organization the user is a member of" do
        let(:user) { create(:user) }
        let(:organization) { create(:organization) }
        let(:scraper) { create(:scraper, private: true, owner: organization) }

        before do
          create(:organizations_user, organization: organization, user: user)
        end

        it { is_expected.not_to be_able_to(:show, scraper) }
        it { is_expected.not_to be_able_to(:edit, scraper) }
        it { is_expected.not_to be_able_to(:destroy, scraper) }
        it { is_expected.not_to be_able_to(:update, scraper) }
        it { is_expected.not_to be_able_to(:watch, scraper) }
        it { is_expected.not_to be_able_to(:data, scraper) }
      end
    end
  end

  context "when an admin" do
    context "when the site is not in read-only mode" do
      let(:user) { create(:user, admin: true) }

      # Just checking for extra permissions an admin is expected to have
      it { is_expected.to be_able_to(:memory_setting, Scraper) }
      it { is_expected.to be_able_to(:create_private, Scraper) }
    end

    context "when the site is in read-only mode" do
      before do
        SiteSetting.read_only_mode = true
      end

      context "with a public scraper" do
        context "when scraper is not owned by the user" do
          let(:user) { create(:user, admin: true) }
          let(:scraper) { create(:scraper) }

          it { is_expected.not_to be_able_to(:new, Scraper) }
          it { is_expected.not_to be_able_to(:create, Scraper) }
          it { is_expected.not_to be_able_to(:watch, scraper) }
          it { is_expected.not_to be_able_to(:memory_setting, Scraper) }
          it { is_expected.not_to be_able_to(:create_private, Scraper) }
        end

        context "when scraper is owned by the user" do
          let(:user) { create(:user, admin: true) }
          let(:scraper) { create(:scraper, owner: user) }

          it { is_expected.not_to be_able_to(:destroy, scraper) }
          it { is_expected.not_to be_able_to(:update, scraper) }
          it { is_expected.not_to be_able_to(:watch, scraper) }
        end

        context "when scraper is owned by an organization the user is a member of" do
          let(:user) { create(:user, admin: true) }
          let(:organization) { create(:organization) }
          let(:scraper) { create(:scraper, owner: organization) }

          before do
            create(:organizations_user, organization: organization, user: user)
          end

          it { is_expected.not_to be_able_to(:destroy, scraper) }
          it { is_expected.not_to be_able_to(:update, scraper) }
          it { is_expected.not_to be_able_to(:watch, scraper) }
        end
      end
    end
  end
end
