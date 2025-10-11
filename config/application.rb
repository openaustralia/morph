require_relative 'boot'

# require 'rails/all' # clean-up deprecation warnings by excluding unused modules with autoload in initialization issues

require 'rails'

# Loaded in the same order as rails/all
require "active_record/railtie"  # ActiveRecord Used (18 files)
# require "active_storage/engine"  # ActiveStorage Not used nor in schema.rb
require "action_controller/railtie"  # ActionController Used (6 files)
require "action_view/railtie"  # ActionView Used (13 files)
require "action_mailer/railtie"  # ActionMailer Used (4 files)
require "active_job/railtie"  # ActiveJob used by sidekiq
# require "action_cable/engine"  # ActionCable Not used (faye/render_sync use their own)
require "action_mailbox/engine"  # ActionMailbox Not directly referenced BUT required for tests to work
# require "action_text/engine"  # ActionText Not used - excluding 
# require "rails/test_unit/railtie"  # TestUnit Not used (we use spec instead) ####
require "sprockets/railtie"  # Sprockets Used (1 files)

# require "active_model/railtie"  # ActiveModel used for validations

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Morph
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.
  end
end
