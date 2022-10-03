# typed: strict
# frozen_string_literal: true

module Morph
  module Environment
    extend T::Sig

    sig { returns(Integer) }
    def self.github_app_id
      get_required_env_integer("GITHUB_APP_ID")
    end

    sig { returns(String) }
    def self.github_app_client_id
      get_required_env_string("GITHUB_APP_CLIENT_ID")
    end

    sig { returns(String) }
    def self.github_app_client_secret
      get_required_env_string("GITHUB_APP_CLIENT_SECRET")
    end

    sig { returns(String) }
    def self.github_app_name
      get_required_env_string("GITHUB_APP_NAME")
    end

    sig { params(env: String).returns(Integer) }
    def self.get_required_env_integer(env)
      v = get_required_env_string(env)
      # TODO: Would be good to have better checking that the string just contains an integer value
      raise "environment variable #{env} needs to be an integer" if v.empty?

      v.to_i
    end

    sig { params(env: String).returns(String) }
    def self.get_required_env_string(env)
      v = ENV.fetch(env, nil)
      raise "environment variable #{env} needs to be set" if v.nil?

      v
    end
  end
end
