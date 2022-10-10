# typed: false
# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  page_action :toggle_read_only_mode, method: :post do
    SiteSetting.toggle_read_only_mode!
    flash[:notice] = "Read-only mode is now #{SiteSetting.read_only_mode ? 'on' : 'off'}"
    redirect_to admin_dashboard_url
  end

  page_action :update_maximum_concurrent_scrapers, method: :post do
    params_maximum_concurrent_scrapers = T.cast(params[:maximum_concurrent_scrapers], T.any(String, Numeric))

    SiteSetting.maximum_concurrent_scrapers = params_maximum_concurrent_scrapers.to_i
    flash[:notice] = "Updated maximum concurrent scrapers to #{SiteSetting.maximum_concurrent_scrapers}"
    redirect_to admin_dashboard_url
  end

  content title: proc { I18n.t("active_admin.dashboard") } do
    columns do
      column do
        panel "Users" do
          para "#{User.where('created_at > ?', 7.days.ago).count} new users in last 7 days"
          para "#{User.count} users total"
        end
      end

      column do
        panel "Scrapers" do
          para "#{Scraper.where('created_at > ?', 7.days.ago).count} new scrapers in last 7 days"
          para "#{Scraper.count} scrapers total"
        end
      end
    end

    div class: "blank_slate_container", id: "dashboard_default_message" do
      para do
        if SiteSetting.read_only_mode
          button_to "Switch off site-wide read-only mode", admin_dashboard_toggle_read_only_mode_path
        else
          button_to "Go into site-wide read-only mode", admin_dashboard_toggle_read_only_mode_path
        end
      end
      para do
        render "maximum_concurrent_scrapers_form"
      end
    end

    # Here is an example of a simple dashboard with columns and panels.
    #
    # columns do
    #   column do
    #     panel "Recent Posts" do
    #       ul do
    #         Post.recent(5).map do |post|
    #           li link_to(post.title, admin_post_path(post))
    #         end
    #       end
    #     end
    #   end

    #   column do
    #     panel "Info" do
    #       para "Welcome to ActiveAdmin."
    #     end
    #   end
    # end
  end
end
