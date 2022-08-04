# typed: false
# frozen_string_literal: true

module Admin
  class SiteSettingsController < ApplicationController
    def toggle_read_only_mode
      authorize! :toggle_read_only_mode, SiteSetting
      SiteSetting.toggle_read_only_mode!
      flash[:notice] = "Read-only mode is now #{SiteSetting.read_only_mode ? 'on' : 'off'}"
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
