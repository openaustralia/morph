# typed: true
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

    @scrapers = T.must(@owner).scrapers

    # Split out scrapers into different groups
    @running_scrapers = []
    @erroring_scrapers = []
    @other_scrapers = []
    @scrapers.each do |scraper|
      if scraper.running?
        @running_scrapers << scraper
      elsif scraper.requires_attention?
        @erroring_scrapers << scraper
      else
        @other_scrapers << scraper
      end
    end
  end

  def settings_redirect
    redirect_to settings_owner_url(current_user)
  end

  def settings; end

  def reset_key
    T.must(@owner).set_api_key
    T.must(@owner).save!
    redirect_to settings_owner_url(@owner)
  end

  # Toggle whether we're watching this user / organization
  def watch
    user = T.must(current_user)
    user.toggle_watch(T.must(@owner))
    redirect_back(fallback_location: root_path)
  end

  private

  sig { void }
  def load_resource
    @owner = T.let(Owner.friendly.find(params[:id]), T.nilable(Owner))
  end
end
