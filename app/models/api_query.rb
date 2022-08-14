# typed: strict
# frozen_string_literal: true

# A record of a download or an API query
class ApiQuery < ApplicationRecord
  extend T::Sig
  belongs_to :scraper
  belongs_to :owner

  # Downloads made after this date are visible to everyone
  # We deployed the notice at 6:23PM, May 7, 2015 (Sydney time)
  VISIBLE_CUT_OFF_DATE = T.let(DateTime.new(2015, 5, 7, 18, 23, 0, "+10"), DateTime)

  scope :visible, -> { where("created_at > ?", VISIBLE_CUT_OFF_DATE) }

  # disable STI
  self.inheritance_column = :_type_disabled

  sig { params(query: String, scraper: Scraper, owner: Owner, benchmark: Benchmark::Tms, size: Integer, type: String, format: String).void }
  def self.log!(query:, scraper:, owner:, benchmark:, size:, type:, format:)
    ApiQuery.create!(
      query: query, scraper_id: scraper.id,
      owner_id: owner.id, utime: (benchmark.cutime + benchmark.utime),
      stime: (benchmark.cstime + benchmark.stime),
      wall_time: benchmark.real, size: size, type: type, format: format
    )
  end
end
