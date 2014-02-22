module StaticHelper
  # TODO Move this bit of configuration somewhere sensible
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

  def curl_command(api_key, scraper, sql)
    'curl -H "x-api-key:'.html_safe + api_key + '" "'.html_safe + api_root + scraper +
      '/data.json?query='.html_safe + sql + '"'.html_safe
  end
end
