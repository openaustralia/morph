# typed: strict
# frozen_string_literal: true

module Discourse
  class SingleSignOn
    extend T::Sig

    ACCESSORS = T.let(%i[nonce name username email about_me external_email external_username external_name external_id].freeze, T::Array[Symbol])

    sig { returns(T.nilable(String)) }
    attr_accessor :nonce

    sig { returns(T.nilable(String)) }
    attr_accessor :name

    sig { returns(T.nilable(String)) }
    attr_accessor :username

    sig { returns(T.nilable(String)) }
    attr_accessor :email

    sig { returns(T.nilable(String)) }
    attr_accessor :about_me

    sig { returns(T.nilable(String)) }
    attr_accessor :external_email

    sig { returns(T.nilable(String)) }
    attr_accessor :external_username

    sig { returns(T.nilable(String)) }
    attr_accessor :external_name

    sig { returns(T.nilable(Integer)) }
    attr_accessor :external_id

    sig { params(sso_secret: String).returns(String) }
    attr_writer :sso_secret

    sig { params(sso_url: String).returns(String) }
    attr_writer :sso_url

    sig { returns(T.noreturn) }
    def self.sso_secret
      raise "sso_secret not implemented on class, be sure to set it on instance"
    end

    sig { returns(T.noreturn) }
    def self.sso_url
      raise "sso_url not implemented on class, be sure to set it on instance"
    end

    sig { void }
    def initialize
      @sso_secret = T.let(nil, T.nilable(String))
      @sso_url = T.let(nil, T.nilable(String))
    end

    sig { returns(String) }
    def sso_secret
      @sso_secret || self.class.sso_secret
    end

    sig { returns(String) }
    def sso_url
      @sso_url || self.class.sso_url
    end

    sig { params(payload: String, sso_secret: T.nilable(String)).returns(SingleSignOn) }
    def self.parse(payload, sso_secret = nil)
      sso = new
      sso.sso_secret = sso_secret if sso_secret

      parsed = Rack::Utils.parse_query(payload)

      raise "Bad signature for payload" if sso.sign(parsed["sso"]) != parsed["sig"]

      decoded = Base64.decode64(parsed["sso"])
      decoded_hash = Rack::Utils.parse_query(decoded)

      ACCESSORS.each do |k|
        val = decoded_hash[k.to_s]
        sso.send("#{k}=", val)
      end
      sso
    end

    sig { params(payload: String).returns(String) }
    def sign(payload)
      OpenSSL::HMAC.hexdigest("sha256", sso_secret, payload)
    end

    sig { params(base_url: T.nilable(String)).returns(String) }
    def to_url(base_url = nil)
      base = (base_url || sso_url).to_s
      "#{base}#{base.include?('?') ? '&' : '?'}#{payload}"
    end

    sig { returns(String) }
    def payload
      payload = Base64.encode64(unsigned_payload)
      "sso=#{CGI.escape(payload)}&sig=#{sign(payload)}"
    end

    sig { returns(String) }
    def unsigned_payload
      payload = {}
      ACCESSORS.each do |k|
        next unless (val = send k)

        payload[k] = val
      end

      Rack::Utils.build_query(payload)
    end
  end
end
