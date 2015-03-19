# HACK Temporary workaround until I figure out the root cause
if Rails.env.production?
  OmniAuth.config.full_host = Proc.new do |env|
    # Horrible hack to deal with the difference between production and local vm
    puts "HTTP_HOST: #{env['HTTP_HOST']}"
    if env["HTTP_HOST"] == "dev.morph.io"
      "https://dev.morph.io"
    else
      "https://morph.io"
    end
  end
end
