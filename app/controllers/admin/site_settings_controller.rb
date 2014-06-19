module Admin
  class SiteSettingsController < ApplicationController
    def toggle_read_only_mode
      authorize! :toggle_read_only_mode, SiteSetting
      SiteSetting.toggle_read_only_mode!
      flash[:notice] = "Read-only mode is now " + (SiteSetting.read_only_mode ? "on" : "off")
      redirect_to admin_dashboard_url
    end
  end
end
