# typed: strict
# frozen_string_literal: true

class OwnersController < ApplicationController
  extend T::Sig

  before_action :authenticate_user!, except: :show
  before_action :load_resource, except: :settings_redirect
  authorize_resource
  skip_authorize_resource only: :settings_redirect

  sig { void }
  def show
    # Whether this user has just become a supporter
    @new_supporter = T.let(session[:new_supporter], T.nilable(T::Boolean))
    # Only do this once
    session[:new_supporter] = false if @new_supporter

    scrapers = Scraper.accessible_by(current_ability).where(owner: @owner)
    @scrapers = T.let(scrapers, T.nilable(ActiveRecord::Relation))

    # Split out scrapers into different groups
    running_scrapers = []
    erroring_scrapers = []
    other_scrapers = []
    scrapers.each do |scraper|
      if scraper.running?
        running_scrapers << scraper
      elsif scraper.requires_attention?
        erroring_scrapers << scraper
      else
        other_scrapers << scraper
      end
    end
    @running_scrapers = T.let(running_scrapers, T.nilable(T::Array[Scraper]))
    @erroring_scrapers = T.let(erroring_scrapers, T.nilable(T::Array[Scraper]))
    @other_scrapers = T.let(other_scrapers, T.nilable(T::Array[Scraper]))

    @other_scrapers_contributed_to = T.let(@owner.other_scrapers_contributed_to.accessible_by(current_ability), T.nilable(ActiveRecord::AssociationRelation)) if @owner.is_a?(User)
  end

  sig { void }
  def settings_redirect
    redirect_to settings_owner_url(current_user)
  end

  sig { void }
  def settings; end

  sig { void }
  def reset_key
    T.must(@owner).set_api_key
    T.must(@owner).save!
    redirect_to settings_owner_url(@owner)
  end

  # Toggle whether we're watching this user / organization
  sig { void }
  def watch
    user = T.must(current_user)
    user.toggle_watch(T.must(@owner))
    redirect_back(fallback_location: root_path)
  end

  private

  # Overriding the default ability class name used because we've split them out. See
  # https://github.com/CanCanCommunity/cancancan/blob/develop/docs/split_ability.md
  sig { returns(Ability) }
  def current_ability
    @current_ability ||= T.let(OwnerAbility.new(current_user).merge(ScraperAbility.new(current_user)), T.nilable(OwnerAbility))
  end

  sig { void }
  def load_resource
    @owner = T.let(Owner.friendly.find(params[:id]), T.nilable(Owner))
  end
end
