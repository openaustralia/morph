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
        VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
          create(:scraper, owner: user, name: "a_scraper",
                           full_name: "mlandauer/a_scraper")
        end
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
          VCR.use_cassette("scraper_validations",
                           allow_playback_repeats: true) do
            Scraper.create(owner: user, name: "a_scraper",
                           full_name: "mlandauer/a_scraper")
          end
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
          VCR.use_cassette("scraper_validations",
                           allow_playback_repeats: true) do
            Scraper.create(owner: organization, name: "a_scraper",
                           full_name: "org/a_scraper")
          end
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
        VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
          Scraper.create(owner: other_user, name: "a_scraper",
                         full_name: "otheruser/a_scraper")
        end
        expect { delete :destroy, params: { id: "otheruser/a_scraper" } }
          .to raise_error(CanCan::AccessDenied)
        expect(Scraper.count).to eq 1
      end

      it "does not allow you to delete a scraper if it's owner is an organisation your're not part of" do
        other_organisation = Organization.create(nickname: "otherorg")
        VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
          Scraper.create(owner: other_organisation, name: "a_scraper",
                         full_name: "otherorg/a_scraper")
        end
        expect { delete :destroy, params: { id: "otherorg/a_scraper" } }
          .to raise_error(CanCan::AccessDenied)
        expect(Scraper.count).to eq 1
      end
    end
  end

  describe "#create_scraperwiki" do
    before do
      sign_in user
    end

    it "errors if the scraper already exists on morph.io" do
      scraperwiki_double = double("Morph::Scraperwiki",
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        create :scraper, owner: user
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id,
          scraperwiki_shortname: "my_scraper"
        } }
      end

      expect(assigns(:scraper).errors[:name])
        .to eq ["is already taken on morph.io"]
    end

    it "errors if the scraper already exists on GitHub" do
      scraperwiki_double = double("Morph::Scraperwiki",
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)
      expect(Octokit).to receive(:repository?).and_return(true)

      post :create_scraperwiki, params: { scraper: {
        name: "my_scraper",
        owner_id: user.id,
        scraperwiki_shortname: "my_scraper"
      } }

      expect(assigns(:scraper).errors[:name])
        .to eq ["is already taken on GitHub"]
    end

    it "errors if the ScraperWiki shortname is not set" do
      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id
        } }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ["cannot be blank"]
    end

    it "errors if the scraper doesn't exist on ScraperWiki" do
      scraperwiki_double = double("Morph::Scraperwiki",
                                  exists?: false,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id,
          scraperwiki_shortname: "missing_scraper"
        } }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ["doesn't exist on ScraperWiki"]
    end

    it "errors if the ScraperWiki scraper is private" do
      scraperwiki_double = double("Morph::Scraperwiki",
                                  exists?: true,
                                  private_scraper?: true,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id,
          scraperwiki_shortname: "private_scraper"
        } }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ["needs to be a public scraper on ScraperWiki"]
    end

    it "errors if the ScraperWiki name given is a view" do
      scraperwiki_double = double("Morph::Scraperwiki",
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: true)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id,
          scraperwiki_shortname: "some_view"
        } }
      end

      expect(assigns(:scraper).errors[:scraperwiki_shortname])
        .to eq ["can't be a ScraperWiki view"]
    end

    it "calls ForkScraperwikiWorker if all looks good" do
      scraperwiki_double = double("Morph::Scraperwiki",
                                  exists?: true,
                                  private_scraper?: false,
                                  view?: false)
      expect(Morph::Scraperwiki).to receive(:new).at_least(:once)
                                                 .and_return(scraperwiki_double)

      expect(ForkScraperwikiWorker).to receive(:perform_async)

      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id,
          scraperwiki_shortname: "missing_scraper"
        } }
      end
    end

    it "does not attempt to fork if ScraperWiki shortname is not set" do
      expect(ForkScraperwikiWorker).not_to receive(:perform_async)

      VCR.use_cassette("scraper_validations", allow_playback_repeats: true) do
        post :create_scraperwiki, params: { scraper: {
          name: "my_scraper",
          owner_id: user.id
        } }
      end
    end
  end
end
