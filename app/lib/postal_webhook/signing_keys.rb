# typed: strict
# frozen_string_literal: true

module PostalWebhook
  # The public keys Postal publishes for the key it signs webhooks with. Postal signs with one installation-wide key and
  # publishes the matching public key as a JWK Set at a well-known address, so we check against whatever it publishes
  # now rather than holding a copy. A key rotation on the Postal server then needs no change here.
  # https://docs.postalserver.io/developer/webhooks and https://www.rfc-editor.org/rfc/rfc7517
  #
  # Adapted from Planning Alerts' PostalSigningKeysService (openaustralia/planningalerts, same licence), using Net::HTTP
  # and building the RSA key by hand so morph needs no new gem.
  class SigningKeys
    extend T::Sig

    class FetchError < StandardError; end

    # Postal gives up on a webhook after 5 seconds and this runs inside that request, so a slower fetch is no use.
    HTTP_TIMEOUT = 2

    # Bump the version to expire every cached copy.
    CACHE_KEY = "postal_webhook/signing_keys/v1"

    # Long enough that a burst of webhooks isn't a fetch each, short enough that a key rotation heals within a
    # quarter of an hour.
    # Events signed with a new key in that window get 403 and are lost, as in Planning Alerts. Failures are cached
    # too, deliberately: that is what stops an outage becoming one outbound request per inbound webhook on an endpoint
    # anyone can post to.
    CACHE_TTL = T.let(15.minutes, ActiveSupport::Duration)

    # While one request refreshes an expired entry, others keep getting the stale copy instead of fetching.
    RACE_CONDITION_TTL = T.let(5.seconds, ActiveSupport::Duration)

    # Returns the RSA public keys, or nil if they can't be determined.
    sig { returns(T.nilable(T::Array[OpenSSL::PKey::RSA])) }
    def self.call
      pems = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL, race_condition_ttl: RACE_CONDITION_TTL) { fetch_pems }
      pems&.map { |pem| OpenSSL::PKey::RSA.new(pem) }
    end

    # PEM strings rather than key objects, because the production cache is memcached and what we store has to survive
    # Marshal. Network failures and a malformed body degrade to nil ("can't check this signature") rather than a 500,
    # and are reported to Sentry, at most once per CACHE_TTL because the result is cached.
    sig { returns(T.nilable(T::Array[String])) }
    def self.fetch_pems
      uri = URI.parse(Rails.configuration.x.postal_jwks_url)
      response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                                                     open_timeout: HTTP_TIMEOUT, read_timeout: HTTP_TIMEOUT) do |http|
        http.get(uri.request_uri)
      end
      return report_failure("HTTP status #{response.code}") unless response.code == "200"

      parsed = JSON.parse(response.body.to_s)
      keys = parsed["keys"] if parsed.is_a?(Hash)
      return report_failure("body has no keys list") unless keys.is_a?(Array)

      keys.filter_map { |jwk| signing_pem(jwk) }.presence || report_failure("no usable RSA signing key")
    rescue Timeout::Error, SocketError, SystemCallError, EOFError, Net::ProtocolError, Net::HTTPBadResponse,
           Net::HTTPHeaderSyntaxError, JSON::ParserError, TypeError, ArgumentError, OpenSSL::OpenSSLError => e
      report_failure("#{e.class}: #{e.message}")
    end

    # The message is fixed and the reason goes in extra, so one outage groups as one Sentry issue.
    sig { params(reason: String).returns(NilClass) }
    def self.report_failure(reason)
      Sentry.capture_exception(
        FetchError.new("Could not fetch Postal's webhook signing keys, so bounce processing is paused"),
        extra: { jwks_url: Rails.configuration.x.postal_jwks_url, reason: reason }
      )
      nil
    end

    # Only RSA keys marked for signatures, or with no usage stated ("use" is optional in RFC 7517). Never encryption keys.
    sig { params(jwk: T.untyped).returns(T.nilable(String)) }
    def self.signing_pem(jwk)
      return unless jwk.is_a?(Hash) && jwk["kty"] == "RSA" && [nil, "sig"].include?(jwk["use"])
      return unless jwk["n"].is_a?(String) && jwk["e"].is_a?(String)

      modulus = OpenSSL::BN.new(Base64.urlsafe_decode64(jwk["n"]), 2)
      exponent = OpenSSL::BN.new(Base64.urlsafe_decode64(jwk["e"]), 2)
      sequence = OpenSSL::ASN1::Sequence([OpenSSL::ASN1::Integer(modulus), OpenSSL::ASN1::Integer(exponent)])
      OpenSSL::PKey::RSA.new(sequence.to_der).to_pem
    end
    private_class_method :fetch_pems, :report_failure, :signing_pem
  end
end
