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
end
