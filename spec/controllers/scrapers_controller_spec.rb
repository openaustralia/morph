# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ScrapersController do
  let(:user) { create(:user, nickname: "mlandauer") }
  let(:organization) do
    o = create(:organization, nickname: "org")
    o.users << user
    o
  end

  describe "#destroy" do
    context "when not signed in" do
      it "does not allow you to delete a scraper" do
        create(:scraper, owner: user, name: "a_scraper",
                         full_name: "mlandauer/a_scraper")
        delete :destroy, params: { id: "mlandauer/a_scraper" }
        expect(Scraper.count).to eq 1
      end
    end

    context "when signed in" do
      before do
        sign_in user
      end

      context "when you own the scraper" do
        before do
          Scraper.create(owner: user, name: "a_scraper",
                         full_name: "mlandauer/a_scraper")
        end

        it "allows you to delete the scraper" do
          delete :destroy, params: { id: "mlandauer/a_scraper" }
          expect(Scraper.count).to eq 0
        end

        it "redirects to the owning user" do
          delete :destroy, params: { id: "mlandauer/a_scraper" }
          expect(response).to redirect_to user_url(user)
        end
      end

      context "when an organisation you're part of owns the scraper" do
        before do
          Scraper.create(owner: organization, name: "a_scraper",
                         full_name: "org/a_scraper")
        end

        it "allows you to delete a scraper if it's owner by an organisation you're part of" do
          delete :destroy, params: { id: "org/a_scraper" }
          expect(Scraper.count).to eq 0
        end

        it "redirects to the owning organisation" do
          delete :destroy, params: { id: "org/a_scraper" }
          expect(response).to redirect_to organization_url(organization)
        end
      end

      it "does not allow you to delete a scraper if you don't own the scraper" do
        other_user = User.create(nickname: "otheruser")
        Scraper.create(owner: other_user, name: "a_scraper",
                       full_name: "otheruser/a_scraper")
        expect { delete :destroy, params: { id: "otheruser/a_scraper" } }
          .to raise_error(CanCan::AccessDenied)
        expect(Scraper.count).to eq 1
      end

      it "does not allow you to delete a scraper if it's owner is an organisation your're not part of" do
        other_organisation = Organization.create(nickname: "otherorg")
        Scraper.create(owner: other_organisation, name: "a_scraper",
                       full_name: "otherorg/a_scraper")
        expect { delete :destroy, params: { id: "otherorg/a_scraper" } }
          .to raise_error(CanCan::AccessDenied)
        expect(Scraper.count).to eq 1
      end
    end
  end
end
