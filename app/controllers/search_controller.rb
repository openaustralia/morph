# typed: strict
# frozen_string_literal: true

class SearchController < ApplicationController
  extend T::Sig

  sig { void }
  def search
    default_owner_search_params = { highlight: { fields: %i[nickname name company blog] }, page: params[:page], per_page: 10 }
    default_scraper_search_params = { fields: [{ full_name: :word_middle }, :description, { scraped_domain_names: :word_end }], highlight: true, page: params[:page], per_page: 10 }

    q = T.cast(params[:q], String)
    @q = T.let(q, T.nilable(String))
    type = T.cast(params[:type], T.nilable(String))
    @type = T.let(type, T.nilable(String))
    show = T.cast(params[:show], T.nilable(String))
    @show = T.let(show, T.nilable(String))

    @owners = T.let(Owner.search(@q, default_owner_search_params), T.nilable(Searchkick::Relation))
    # We're sending the id of every scraper we are allowed to view to searchkick. This is obviously not ideal as it will grow as the number of scrapers grow.
    # TODO: Would it be more sensible to only send the ids that we *can't* view?
    # Or is there some other entirely more sensible approach to this problem? We just don't want to duplicate the authorisation logic in ScraperAbility here.
    ids = Scraper.accessible_by(current_ability).ids
    @all_scrapers = T.let(Scraper.search(@q, default_scraper_search_params.merge(where: { id: ids })), T.nilable(Searchkick::Relation))
    @filtered_scrapers = T.let(Scraper.search(@q, default_scraper_search_params.merge(where: { data?: true, id: ids })), T.nilable(Searchkick::Relation))

    @scrapers = T.let(@show == "all" ? @all_scrapers : @filtered_scrapers, T.nilable(Searchkick::Relation))
  end

  private

  # Overriding the default ability class name used because we've split them out. See
  # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/split_ability.md
  sig { returns(ScraperAbility) }
  def current_ability
    @current_ability ||= T.let(ScraperAbility.new(current_user), T.nilable(ScraperAbility))
  end
end
