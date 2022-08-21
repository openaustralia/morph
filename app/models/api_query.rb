# typed: strict
# frozen_string_literal: true

# A record of a download or an API query
class ApiQuery < ApplicationRecord
  extend T::Sig
  belongs_to :scraper
  belongs_to :owner

  # disable STI
  self.inheritance_column = :_type_disabled

  sig { params(query: T.nilable(String), scraper: Scraper, owner: Owner, benchmark: Benchmark::Tms, size: Integer, type: String, format: String).void }
  def self.log!(query:, scraper:, owner:, benchmark:, size:, type:, format:)
    ApiQuery.create!(
      query: query, scraper_id: scraper.id,
      owner_id: owner.id, utime: (benchmark.cutime + benchmark.utime),
      stime: (benchmark.cstime + benchmark.stime),
      wall_time: benchmark.real, size: size, type: type, format: format
    )
  end
end
