# Be sure to restart your server when you modify this file.

# Configure sensitive parameters which will be filtered from the log file.
Rails.application.config.filter_parameters += [
  :passw, :secret, :token, :_key, :crypt, :salt, :certificate, :otp, :ssn,
  # Postal's delivery webhooks carry recipient addresses and the receiving server's reply (see PostalController)
  /\Apayload\z/
]
