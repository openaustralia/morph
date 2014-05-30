class OwnersController < ApplicationController
  def show
    @owner = Owner.friendly.find(params[:id])
    @scrapers = @owner.scrapers.includes(:last_run => :log_lines)

    # Split out scrapers into different groups
    @running_scrapers, @erroring_scrapers, @other_scrapers = [], [], []
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

  def settings
    if params[:id]
      @user = User.friendly.find(params[:id])
      if @user != current_user && !current_user.admin?
        render text: "You are not authorised to view this page", status: :unauthorized
        return
      end
    else
      redirect_to owner_settings_url(current_user)
    end
  end

  def reset_key
    # TODO In future we will allow admins to reset other people's keys
    # That's why we're doing this in this slightly roundabout way
    @user = User.friendly.find(params[:id])
    if @user == current_user
      @user.set_api_key
      @user.save!
    end
    redirect_to owner_settings_url(current_user)
  end

  # Toggle whether we're watching this user / organization
  def watch
    owner = Owner.friendly.find(params[:id])
    current_user.toggle_watch(owner)
    redirect_to :back
  end
end
