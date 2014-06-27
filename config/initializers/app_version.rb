unless defined?(APP_VERSION)
  APP_VERSION = Rails.production? ? File.read("REVISION") : `git describe --always`
end
