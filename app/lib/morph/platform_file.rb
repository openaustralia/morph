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
      # early_release means the latest (currently heroku-24) - a scraper that opts into it moves
      # to whatever stack is newest as that changes over time, rather than a fixed one. See
      # 1dde2482 (introduced pointing at heroku-18, the newest stack at the time) and 36f6bfd8
      # (repointed to heroku-24 once that became newest) for how this has moved before.
      # TODO: We should remove support for early_release at some stage
      platform = "heroku-24" if platform == "early_release"
      platform
    end
  end
end
