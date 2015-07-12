module StaticHelper
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

  def quote(a)
    '"'.html_safe + a + '"'.html_safe
  end

  def curl_command(scraper, format, key, sql, callback)
    'curl '.html_safe +
      quote(api_url_in_html(scraper, format, key, sql, callback))
  end

  def curl_command_linked(scraper, format, key, sql, callback)
    url = api_url_in_html(scraper, format, key, sql, callback)
    url_stripped = url.gsub(/<([^>]+)>/, "")
    'curl '.html_safe +
      quote(link_to url, url_stripped, id: "api_link")
  end

  def api_url_in_html(scraper, format, key, sql, callback)
      api_root.html_safe + scraper + '/data.' + format + '?key='.html_safe + key + '&query='.html_safe + sql + callback
  end
end
