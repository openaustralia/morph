# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe SearchController, type: :controller do
  let(:user) { create(:user) }
  let(:scraper) { create(:scraper, owner: user) }

  before do
    # Stub Searchkick methods to avoid actual search engine calls
    allow(Owner).to receive(:search).and_return(double(results: []))
    allow(Scraper).to receive(:search).and_return(double(results: []))
    allow(Scraper).to receive(:accessible_by).and_return(Scraper.where(id: scraper.id))
  end

  describe "GET #search" do
    context "when not signed in" do
      it "returns http success" do
        get :search
        expect(response).to have_http_status(:success)
      end

      it "searches owners with query parameter" do
        expect(Owner).to receive(:search).with("test", hash_including(page: nil, per_page: 10))
        get :search, params: { q: "test" }
      end

      it "searches scrapers respecting authorization" do
        expect(Scraper).to receive(:accessible_by).and_return(Scraper.where(id: scraper.id))
        get :search, params: { q: "test" }
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
        expect(Owner).to receive(:search).with("query", hash_including(page: "2"))
        get :search, params: { q: "query", page: "2" }
      end

      it "uses ScraperAbility for authorization" do
        expect(Scraper).to receive(:accessible_by)
        get :search, params: { q: "test" }
      end

      it "filters scrapers by default (data? = true)" do
        search_result = double(results: [])
        expect(Scraper).to receive(:search).with(
          "test",
          hash_including(where: hash_including(data?: true))
        ).and_return(search_result)
        get :search, params: { q: "test" }
        expect(assigns(:scrapers)).to eq(search_result)
      end

      it "shows all scrapers when show=all parameter is set" do
        all_search = double(results: [])
        filtered_search = double(results: [])
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
        expect(Owner).to receive(:search).with(nil, anything)
        get :search
      end
    end

    context "with empty query" do
      before { sign_in user }

      it "handles empty query" do
        expect(Owner).to receive(:search).with("", anything)
        get :search, params: { q: "" }
      end
    end

    context "authorization filtering" do
      before { sign_in user }

      it "only searches scrapers accessible by current ability" do
        scraper2 = create(:scraper)
        accessible_scrapers = Scraper.where(id: [scraper.id])
        allow(Scraper).to receive(:accessible_by).and_return(accessible_scrapers)

        expect(Scraper).to receive(:search).with(
          "test",
          hash_including(where: hash_including(id: [scraper.id]))
        ).at_least(:once)

        get :search, params: { q: "test" }
      end
    end

    context "search parameters" do
      before { sign_in user }

      it "configures owner search with correct highlight fields" do
        expect(Owner).to receive(:search).with(
          "test",
          hash_including(highlight: { fields: %i[nickname name company blog] })
        )
        get :search, params: { q: "test" }
      end

      it "configures scraper search with correct fields" do
        expect(Scraper).to receive(:search).with(
          "test",
          hash_including(
            fields: [{ full_name: :word_middle }, :description, { scraped_domain_names: :word_end }],
            highlight: true
          )
        ).at_least(:once)
        get :search, params: { q: "test" }
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
      expect(ability.user).to eq(user)
    end
  end
end
