# Be sure to restart your server when you modify this file.

# Rails 7.0 derives cookie encryption and signing keys with SHA256 where
# Rails 6.1 used SHA1 (active_support.key_generator_hash_digest_class).
# Without this rotator every session and remember-me cookie issued before
# the change becomes unreadable at deploy, logging everyone out. The
# rotator reads cookies under the old SHA1-derived secrets and rewrites
# them under the new ones, exactly as the 7.0 upgrade guide prescribes:
# https://guides.rubyonrails.org/v7.0/upgrading_ruby_on_rails.html
#
# Remove this file once it has been in production long enough for live
# sessions to have been rewritten (they rewrite on first request).
Rails.application.config.after_initialize do
  Rails.application.config.action_dispatch.cookies_rotations.tap do |cookies|
    authenticated_encrypted_cookie_salt = Rails.application.config.action_dispatch.authenticated_encrypted_cookie_salt
    signed_cookie_salt = Rails.application.config.action_dispatch.signed_cookie_salt

    secret_key_base = Rails.application.secret_key_base

    key_generator = ActiveSupport::KeyGenerator.new(
      secret_key_base, iterations: 1000, hash_digest_class: OpenSSL::Digest::SHA1
    )
    key_len = ActiveSupport::MessageEncryptor.key_len

    old_encrypted_secret = key_generator.generate_key(authenticated_encrypted_cookie_salt, key_len)
    old_signed_secret = key_generator.generate_key(signed_cookie_salt)

    cookies.rotate :encrypted, old_encrypted_secret
    cookies.rotate :signed, old_signed_secret
  end
end
