# typed: strict
# frozen_string_literal: true

require "cgi"
require "uri"

module Morph
  module MysqlMigration
    # One MySQL server, described by a URL such as mysql2://user:secret@127.0.0.1:3306/scraping_production.
    # The password is kept apart so it can reach mysqlsh on stdin and never appears in a command line or a log.
    class Connection
      extend T::Sig

      sig { returns(String) }
      attr_reader :host

      sig { returns(Integer) }
      attr_reader :port

      sig { returns(String) }
      attr_reader :username

      sig { returns(String) }
      attr_reader :database

      sig { returns(String) }
      attr_reader :password

      sig { params(host: String, port: Integer, username: String, password: String, database: String).void }
      def initialize(host:, port:, username:, password:, database:)
        @host = host
        @port = port
        @username = username
        @password = password
        @database = database
      end

      sig { params(url: String).returns(Connection) }
      def self.from_url(url)
        uri = URI.parse(url)
        raise ArgumentError, "expected a mysql2://user:password@host:port/database URL" unless %w[mysql mysql2].include?(uri.scheme) && uri.host && uri.user && uri.path.to_s.length > 1

        new(
          host: T.must(uri.host),
          port: uri.port || 3306,
          username: CGI.unescapeURIComponent(T.must(uri.user)),
          password: CGI.unescapeURIComponent(uri.password.to_s),
          database: T.must(uri.path)[1..].to_s
        )
      end

      sig { returns(String) }
      def endpoint
        "#{host}:#{port}"
      end

      # mysqlsh connection URI without the password
      sig { returns(String) }
      def shell_uri
        "#{CGI.escapeURIComponent(username)}@#{host}:#{port}"
      end

      sig { params(other: Connection).returns(T::Boolean) }
      def same_server_and_database?(other)
        endpoint == other.endpoint && database == other.database
      end

      # Never includes the password
      sig { returns(String) }
      def to_s
        "#{username}@#{endpoint}/#{database}"
      end

      sig { params(database: T.nilable(String)).returns(T.untyped) }
      def client(database: self.database)
        # Both sides read as utf8mb4 so values compare as the same characters whatever the stored charset.
        Mysql2::Client.new(
          host: host, port: port, username: username, password: password,
          database: database, encoding: "utf8mb4", reconnect: true,
          init_command: "SET SESSION time_zone = '+00:00'"
        )
      end
    end
  end
end
