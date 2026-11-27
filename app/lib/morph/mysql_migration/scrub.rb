# typed: strict
# frozen_string_literal: true

module Morph
  module MysqlMigration
    class ScrubRefused < StandardError; end

    # Makes a restored copy of production data unable to contact real people or services (#1567):
    # emails become distinct placeholders at an invalid domain, access and remember tokens are cleared, API keys are
    # replaced by random ones (a NULL key would match a request that sends no key at all), and each webhook
    # URL becomes a distinct placeholder, because webhooks has a unique index on (scraper_id, url).
    #
    # It fails closed. It runs only when the environment says outright that it is a rehearsal one, and never when
    # the server name is production's. It is not part of the cutover and is excluded from the 4-hour timing.
    class Scrub
      extend T::Sig

      PRODUCTION_SERVER_NAMES = T.let(%w[morph.io www.morph.io].freeze, T::Array[String])

      sig { params(config: Config).void }
      def initialize(config:)
        @config = config
      end

      sig { void }
      def check_allowed!
        raise ScrubRefused, "refusing to scrub: MORPH_REHEARSAL is not \"true\", so this is not a rehearsal environment" unless @config.rehearsal?

        server_name = @config.server_name.to_s.strip.downcase
        return unless PRODUCTION_SERVER_NAMES.include?(server_name)

        raise ScrubRefused, "refusing to scrub: SERVER_NAME is #{server_name}, which is production"
      end

      # Returns the number of rows changed per table
      sig { params(client: T.untyped).returns(T::Hash[String, Integer]) }
      def run!(client)
        check_allowed!
        {
          "owners" => update_owners(client),
          "webhooks" => update_webhooks(client)
        }
      end

      private

      sig { params(client: T.untyped).returns(Integer) }
      def update_owners(client)
        client.query(<<~SQL.squish)
          UPDATE owners
          SET email = CONCAT('owner-', id, '@example.invalid'),
              access_token = NULL, remember_token = NULL,
              api_key = SHA2(CONCAT('scrubbed-', id, '-', UUID()), 256)
        SQL
        client.affected_rows
      end

      sig { params(client: T.untyped).returns(Integer) }
      def update_webhooks(client)
        client.query("UPDATE webhooks SET url = CONCAT('https://example.invalid/webhooks/', id)")
        client.affected_rows
      end
    end
  end
end
