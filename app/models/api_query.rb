# typed: false
# frozen_string_literal: true

# A record of a download or an API query
class ApiQuery < ApplicationRecord
  belongs_to :scraper
  belongs_to :owner

  # Downloads made after this date are visible to everyone
  # We deployed the notice at 6:23PM, May 7, 2015 (Sydney time)
  VISIBLE_CUT_OFF_DATE = DateTime.new(2015, 5, 7, 18, 23, 0, "+10")

  scope :visible, -> { where("created_at > ?", VISIBLE_CUT_OFF_DATE) }

  # disable STI
  self.inheritance_column = :_type_disabled

  def self.log!(options)
    query = options.delete(:query)
    scraper = options.delete(:scraper)
    owner = options.delete(:owner)
    benchmark = options.delete(:benchmark)
    size = options.delete(:size)
    type = options.delete(:type)
    format = options.delete(:format)
    raise "Invalid options" unless options.empty?

    ApiQuery.create!(
      query: query, scraper_id: scraper.id,
      owner_id: owner.id, utime: (benchmark.cutime + benchmark.utime),
      stime: (benchmark.cstime + benchmark.stime),
      wall_time: benchmark.real, size: size, type: type, format: format
    )
  end
end
