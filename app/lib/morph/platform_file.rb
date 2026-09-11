# typed: strict
# frozen_string_literal: true

module Morph
  # Reads and resolves the `platform` file at the root of a scraper's code, wherever that code
  # physically lives - a synced git checkout (Scraper#repo_path), or a directory freshly unpacked
  # from an api-uploaded tarball with no associated Scraper record at all (see Run#platform).
  module PlatformFile
    extend T::Sig

    sig { params(repo_path: String).returns(T.nilable(String)) }
    def self.read(repo_path)
      platform_file = "#{repo_path}/platform"
      platform = File.read(platform_file).chomp if File.exist?(platform_file)
      # TODO: We should remove support for early_release at some stage
      platform = "heroku-24" if platform == "early_release"
      platform
    end
  end
end
