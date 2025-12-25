# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe SearchController, type: :controller do
  let(:user) { create(:user) }
  let(:scraper) { create(:scraper, owner: user) }

  before do
    # Stub Searchkick methods to avoid actual search engine calls
    # rubocop:disable RSpec/VerifiedDoubles
    # Using unverified doubles for Searchkick::Results because it's an external gem class
    # that doesn't implement methods in a way RSpec verifying doubles can validate
    allow(Owner).to receive(:search).and_return(double(results: []))
    allow(Scraper).to receive(:search).and_return(double(results: []))
    # rubocop:enable RSpec/VerifiedDoubles
    allow(Scraper).to receive(:accessible_by).and_return(Scraper.where(id: scraper.id))
  end

  describe "GET #search" do
    context "when not signed in" do
      it "returns http success" do
        get :search
        expect(response).to have_http_status(:success)
      end

      it "searches owners with query parameter" do
        allow(Owner).to receive(:search)
        get :search, params: { q: "test" }
        expect(Owner).to have_received(:search).with("test", hash_including(page: nil, per_page: 10))
      end

      it "searches scrapers respecting authorization" do
        allow(Scraper).to receive(:accessible_by).and_return(Scraper.where(id: scraper.id))
        get :search, params: { q: "test" }
        expect(Scraper).to have_received(:accessible_by)
      end

      it "assigns instance variables correctly" do
        get :search, params: { q: "test" }
        expect(assigns(:q)).to eq("test")
        expect(assigns(:owners)).not_to be_nil
        expect(assigns(:scrapers)).not_to be_nil
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "returns http success" do
        get :search
        expect(response).to have_http_status(:success)
      end

      it "searches with pagination" do
        allow(Owner).to receive(:search)
        get :search, params: { q: "query", page: "2" }
        expect(Owner).to have_received(:search).with("query", hash_including(page: "2"))
      end

      it "uses ScraperAbility for authorization" do
        allow(Scraper).to receive(:accessible_by).and_return(Scraper.where(id: scraper.id))
        get :search, params: { q: "test" }
        expect(Scraper).to have_received(:accessible_by)
      end

      it "filters scrapers by default (data? = true)" do
        # rubocop:disable RSpec/VerifiedDoubles
        search_result = double(results: [])
        # rubocop:enable RSpec/VerifiedDoubles
        allow(Scraper).to receive(:search).with(
          "test",
          hash_including(where: hash_including(data?: true))
        ).and_return(search_result)
        get :search, params: { q: "test" }
        expect(assigns(:scrapers)).to eq(search_result)
      end

      it "shows all scrapers when show=all parameter is set" do
        # rubocop:disable RSpec/VerifiedDoubles
        all_search = double(results: [])
        filtered_search = double(results: [])
        # rubocop:enable RSpec/VerifiedDoubles
        allow(Scraper).to receive(:search).and_call_original
        allow(Scraper).to receive(:search).with(
          "test",
          hash_including(where: hash_not_including(data?: true))
        ).and_return(all_search)
        allow(Scraper).to receive(:search).with(
          "test",
          hash_including(where: hash_including(data?: true))
        ).and_return(filtered_search)

        get :search, params: { q: "test", show: "all" }
        expect(assigns(:scrapers)).to eq(all_search)
      end

      it "assigns type parameter" do
        get :search, params: { q: "test", type: "scrapers" }
        expect(assigns(:type)).to eq("scrapers")
      end

      it "assigns show parameter" do
        get :search, params: { q: "test", show: "all" }
        expect(assigns(:show)).to eq("all")
      end
    end

    context "with nil query" do
      before { sign_in user }

      it "handles nil query gracefully" do
        allow(Owner).to receive(:search)
        get :search
        expect(Owner).to have_received(:search).with(nil, anything)
      end
    end

    context "with empty query" do
      before { sign_in user }

      it "handles empty query" do
        allow(Owner).to receive(:search)
        get :search, params: { q: "" }
        expect(Owner).to have_received(:search).with("", anything)
      end
    end

    context "when filtering by authorization" do
      before { sign_in user }

      it "only searches scrapers accessible by current ability" do
        create(:scraper)
        accessible_scrapers = Scraper.where(id: [scraper.id])
        allow(Scraper).to receive(:accessible_by).and_return(accessible_scrapers)
        allow(Scraper).to receive(:search).and_call_original

        get :search, params: { q: "test" }

        expect(Scraper).to have_received(:search).with(
          "test",
          hash_including(where: hash_including(id: [scraper.id]))
        ).at_least(:once)
      end
    end

    context "with search parameters" do
      before { sign_in user }

      it "configures owner search with correct highlight fields" do
        allow(Owner).to receive(:search)
        get :search, params: { q: "test" }
        expect(Owner).to have_received(:search).with(
          "test",
          hash_including(highlight: { fields: %i[nickname name company blog] })
        )
      end

      it "configures scraper search with correct fields" do
        allow(Scraper).to receive(:search).and_call_original
        get :search, params: { q: "test" }
        expect(Scraper).to have_received(:search).with(
          "test",
          hash_including(
            fields: [{ full_name: :word_middle }, :description, { scraped_domain_names: :word_end }],
            highlight: true
          )
        ).at_least(:once)
      end
    end
  end

  describe "#current_ability" do
    before { sign_in user }

    it "uses ScraperAbility instead of default Ability" do
      get :search
      ability = controller.send(:current_ability)
      expect(ability).to be_a(ScraperAbility)
    end

    it "initializes ability with current_user" do
      get :search
      ability = controller.send(:current_ability)
      pending("FIXME: There is no user attribute for this ability - what are we trying to test?")
      expect(ability.user).to eq(user)
    end
  end
end
