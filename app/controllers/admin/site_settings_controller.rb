module Admin
  class SiteSettingsController < ApplicationController
    # Having to hand craft the form for post to update_maximum_concurrent_scrapers
    # so doesn't include the authenticity_token. Not a big deal because it's only
    # accessible by admins anyway
    skip_before_filter :verify_authenticity_token, only: [:update_maximum_concurrent_scrapers]

    def toggle_read_only_mode
      authorize! :toggle_read_only_mode, SiteSetting
      SiteSetting.toggle_read_only_mode!
      flash[:notice] = "Read-only mode is now " + (SiteSetting.read_only_mode ? "on" : "off")
      redirect_to admin_dashboard_url
    end

    def update_maximum_concurrent_scrapers
      authorize! :update_sidekiq_maximum_concurrent_scrapers, SiteSetting
      SiteSetting.maximum_concurrent_scrapers = params[:maximum_concurrent_scrapers]
      flash[:notice] = "Updated maximum concurrent scrapers to #{SiteSetting.maximum_concurrent_scrapers}"
      redirect_to admin_dashboard_url
    end
  end
end
