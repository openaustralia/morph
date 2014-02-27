Morph::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Send mail via Mailcatcher and raise an error if there is a problem
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  config.action_mailer.smtp_settings = { :address => "localhost", :port => 1025 }
  # To test sending via Gmail comment out line above and uncomment lines below
  # config.action_mailer.smtp_settings = {
  #   address: "smtp.gmail.com",
  #   port: 587,
  #   domain: "gmail.com",
  #   authentication: "plain",
  #   enable_starttls_auto: true,
  #   user_name: "GMAIL_USERNAME",
  #   password: "GMAIL_PASSWORD"
  # }

  # Add Rack::LiveReload to the bottom of the middleware stack with the default options.
  #config.middleware.use Rack::LiveReload

  # config.after_initialize do
  #   Bullet.enable = true
  #   #Bullet.alert = true
  #   Bullet.bullet_logger = true
  #   Bullet.console = true
  #   #Bullet.growl = true
  #   Bullet.rails_logger = true
  #   Bullet.add_footer = true
  # end
end

# So that the same host setting is available outside the mailer
Morph::Application.default_url_options = Morph::Application.config.action_mailer.default_url_options