unless defined?(APP_VERSION)
  revision_file = File.join(Rails.root, "REVISION")
  APP_VERSION = Rails.env.production? && File.exist?(revision_file) ? File.read(revision_file)[0..6] : `git describe --always`
end
