# HACK Temporary workaround until I figure out the root cause
if Rails.env.production?
  OmniAuth.config.full_host = "https://morph.io"
end
