# HACK Temporary workaround until I figure out the root cause
if Rails.env.production?
  OmniAuth.config.full_host = Proc.new do |env|
    "https://" + env["HTTP_HOST"]
  end
end
