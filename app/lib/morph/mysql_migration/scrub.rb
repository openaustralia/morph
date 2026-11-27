# typed: strict
# frozen_string_literal: true

module Morph
  module MysqlMigration
    class ScrubRefused < StandardError; end

    # Makes a restored copy of production data unable to contact real people or services (#1567):
    # emails become distinct placeholders at an invalid domain, scraper variable values (which hold secrets) become one
    # fixed placeholder, suppressed addresses become distinct addresses that cannot deliver, reply excerpts become fixed text, IP addresses
    # become one documentation-range address, access and remember tokens are cleared, API keys are
    # replaced by random ones (a NULL key would match a request that sends no key at all), and each webhook
    # URL becomes a distinct placeholder, because webhooks has a unique index on (scraper_id, url).
    #
    # It fails closed. It runs only when the environment says outright that it is a rehearsal one, and never when
    # the server name is production's. It is not part of the cutover and is excluded from the 4-hour timing.
    class Scrub
      extend T::Sig

      VARIABLE_PLACEHOLDER = "scrubbed-for-rehearsal"
      REPLY_PLACEHOLDER = "Reply text removed for rehearsal"
      # From the documentation range 192.0.2.0/24 (RFC 5737), so it never routes to anyone
      IP_PLACEHOLDER = "192.0.2.1"
      # Every column in db/schema.rb that holds an IP address. Empty values stay empty, as a person who never signed in
      # has no address. Add a column here if a migration adds one.
      IP_COLUMNS = T.let({ "owners" => %w[current_sign_in_ip last_sign_in_ip], "runs" => %w[ip_address] }.freeze, T::Hash[String, T::Array[String]])

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
          "webhooks" => update_webhooks(client),
          "variables" => update_variables(client),
          "email_suppressions" => update_email_suppressions(client),
          "ip_addresses" => update_ip_addresses(client)
        }
      end

      # What is still real after the scrub. An empty list means every value it covers has been replaced.
      # API keys are random after the scrub and cannot be told from real ones, so only a missing key is reported.
      sig { params(client: T.untyped).returns(T::Array[String]) }
      def remaining_real_values(client)
        checks = {
          "owners with an email that is not a placeholder" => "SELECT COUNT(*) FROM owners WHERE email IS NULL OR email NOT LIKE 'owner-%@example.invalid'",
          "owners with an access or remember token" => "SELECT COUNT(*) FROM owners WHERE access_token IS NOT NULL OR remember_token IS NOT NULL",
          "owners without an API key" => "SELECT COUNT(*) FROM owners WHERE api_key IS NULL",
          "webhooks with a URL that is not a placeholder" => "SELECT COUNT(*) FROM webhooks WHERE url NOT LIKE 'https://example.invalid/webhooks/%'",
          "variables with a value that is not the placeholder" => "SELECT COUNT(*) FROM variables WHERE value <> '#{VARIABLE_PLACEHOLDER}'",
          "suppressed addresses that are not placeholders" => "SELECT COUNT(*) FROM email_suppressions WHERE address NOT LIKE 'suppressed-%@example.invalid'",
          "reply excerpts that are not the placeholder" => "SELECT COUNT(*) FROM email_suppressions WHERE reply_excerpt IS NOT NULL AND reply_excerpt <> '#{REPLY_PLACEHOLDER}'"
        }.merge(ip_checks)
        checks.filter_map do |description, sql|
          count = client.query(sql, as: :array).first.first.to_i
          "#{count} #{description}" if count.positive?
        end
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

      sig { returns(T::Hash[String, String]) }
      def ip_checks
        IP_COLUMNS.flat_map do |table, columns|
          columns.map do |column|
            ["#{table}.#{column} values that are not the placeholder address",
             "SELECT COUNT(*) FROM #{table} WHERE #{column} IS NOT NULL AND #{column} <> '#{IP_PLACEHOLDER}'"]
          end
        end.to_h
      end

      # Returns the number of values changed across every IP column
      sig { params(client: T.untyped).returns(Integer) }
      def update_ip_addresses(client)
        IP_COLUMNS.sum do |table, columns|
          assignments = columns.map { |c| "#{c} = IF(#{c} IS NULL, NULL, '#{IP_PLACEHOLDER}')" }.join(", ")
          client.query("UPDATE #{table} SET #{assignments}")
          client.affected_rows
        end
      end

      sig { params(client: T.untyped).returns(Integer) }
      def update_variables(client)
        client.query("UPDATE variables SET value = '#{VARIABLE_PLACEHOLDER}'")
        client.affected_rows
      end

      sig { params(client: T.untyped).returns(Integer) }
      def update_email_suppressions(client)
        client.query(<<~SQL.squish)
          UPDATE email_suppressions
          SET address = CONCAT('suppressed-', id, '@example.invalid'),
              reply_excerpt = IF(reply_excerpt IS NULL, NULL, '#{REPLY_PLACEHOLDER}')
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
