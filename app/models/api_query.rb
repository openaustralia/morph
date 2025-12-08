# typed: strict
# frozen_string_literal: true

# A record of a download or an API query
# == Schema Information
#
# Table name: api_queries
#
#  id         :integer          not null, primary key
#  format     :string(255)
#  query      :text(65535)
#  size       :integer
#  stime      :float(24)
#  type       :string(255)
#  utime      :float(24)
#  wall_time  :float(24)
#  created_at :datetime
#  updated_at :datetime
#  owner_id   :integer
#  scraper_id :integer
#
# Indexes
#
#  index_api_queries_on_created_at  (created_at)
#  index_api_queries_on_owner_id    (owner_id)
#  index_api_queries_on_scraper_id  (scraper_id)
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#
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
