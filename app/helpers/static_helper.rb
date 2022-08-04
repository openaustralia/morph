# typed: false
# frozen_string_literal: true

module StaticHelper
  # For sorbet
  include GeneratedUrlHelpersModule
  include ActionView::Helpers::OutputSafetyHelper
  include ActionView::Helpers::UrlHelper

  # TODO: Move this bit of configuration somewhere sensible
  def api_host
    if Rails.env.development?
      request.host
    else
      "api.morph.io"
    end
  end

  def api_root
    if Rails.env.development?
      root_url
    else
      root_url(host: api_host)
    end
  end

  def quote(text)
    safe_join(['"', text, '"'])
  end

  def curl_command(scraper, format, key, sql, callback)
    safe_join(["curl ", quote(api_url_in_html(scraper, format, key, sql, callback))])
  end

  def curl_command_linked(scraper, format, key, sql, callback)
    url = api_url_in_html(scraper, format, key, sql, callback)
    url_stripped = url.gsub(/<([^>]+)>/, "")
    safe_join(["curl ", quote(link_to(url, url_stripped, id: "api_link"))])
  end

  def api_url_in_html(scraper, format, key, sql, callback)
    safe_join([api_root, scraper, "/data.", format, "?key=", key, "&query=", sql, callback])
  end
end
