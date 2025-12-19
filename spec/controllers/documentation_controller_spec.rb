# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe DocumentationController, type: :controller do
  describe "GET #api" do
    let(:scraper) { create(:scraper, full_name: "test/example-scraper") }
    let(:default_scraper) { create(:scraper, full_name: "mlandauer/scraper-blue-mountains") }

    context "with no scraper parameter" do
      before { default_scraper }

      it "returns http success" do
        get :api
        expect(response).to have_http_status(:success)
      end

      it "uses the default scraper" do
        get :api
        expect(assigns(:scraper)).to eq(default_scraper)
      end

      it "sets the query from the scraper database" do
        database = double(select_first_ten: "SELECT * FROM data LIMIT 10")
        allow_any_instance_of(Scraper).to receive(:database).and_return(database)
        get :api
        expect(assigns(:query)).to eq("SELECT * FROM data LIMIT 10")
      end
    end

    context "with scraper parameter" do
      before { scraper }

      it "returns http success" do
        get :api, params: { scraper: "test/example-scraper" }
        expect(response).to have_http_status(:success)
      end

      it "finds the specified scraper" do
        get :api, params: { scraper: "test/example-scraper" }
        expect(assigns(:scraper)).to eq(scraper)
      end

      it "sets the query from the specified scraper" do
        database = double(select_first_ten: "SELECT * FROM custom LIMIT 10")
        allow_any_instance_of(Scraper).to receive(:database).and_return(database)
        get :api, params: { scraper: "test/example-scraper" }
        expect(assigns(:query)).to eq("SELECT * FROM custom LIMIT 10")
      end
    end

    context "when specified scraper not found and no default exists" do
      it "falls back to first scraper" do
        first_scraper = create(:scraper)
        get :api, params: { scraper: "nonexistent/scraper" }
        expect(assigns(:scraper)).to eq(first_scraper)
      end
    end

    context "with maximal scraper data" do
      let(:maximal_scraper) { create(:scraper, :maximal) }

      before { maximal_scraper }

      it "handles maximal scraper data" do
        get :api, params: { scraper: maximal_scraper.full_name }
        expect(response).to have_http_status(:success)
        expect(assigns(:scraper)).to eq(maximal_scraper)
      end
    end
  end
end
