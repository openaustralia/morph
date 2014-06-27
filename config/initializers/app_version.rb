unless defined?(APP_VERSION)
  APP_VERSION = Rails.env.production? ? File.read("REVISION") : `git describe --always`
end
