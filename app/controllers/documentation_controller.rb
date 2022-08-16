# typed: strict
# frozen_string_literal: true

class DocumentationController < ApplicationController
  extend T::Sig

  sig { void }
  def api
    # Example scraper
    scraper = Scraper.find_by(full_name: params[:scraper] || "mlandauer/scraper-blue-mountains") || Scraper.first!
    @scraper = T.let(scraper, T.nilable(Scraper))
    @query = T.let(scraper.database.select_first_ten, T.nilable(String))
  end
end
