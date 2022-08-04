# typed: false
# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

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
          button_to "Switch off site-wide read-only mode", toggle_read_only_mode_admin_site_settings_path
        else
          button_to "Go into site-wide read-only mode", toggle_read_only_mode_admin_site_settings_path
        end
      end
      para do
        render "maximum_concurrent_scrapers_form"
      end
    end

    panel "Sqlite database not transferred bug debugging help" do
      para do
        text_node "This is here to help debug the issue"
        a "https://github.com/openaustralia/morph/issues/1064", href: "https://github.com/openaustralia/morph/issues/1064"
      end
      # For the time being just look at runs in the last month
      runs = Run.order(finished_at: :desc).where(status_code: 998).where("finished_at > ?", 1.month.ago)
      # Only highlight runs where there is actually data.sqlite stored on the server because
      # we would always expect there to be a data.sqlite output
      run = runs.find do |r|
        File.exist?(File.join(r.data_path, "data.sqlite"))
      end
      if run
        time = run.finished_at.localtime
        para "Last time there was a problem: #{time_ago_in_words(time)} ago (#{time})"
        para do
          text_node "On scraper:"
          a run.scraper.full_name, href: scraper_path(run.scraper)
        end
      else
        para "No problems in the last month"
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
