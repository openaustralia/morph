class ApiQuery < ActiveRecord::Base

  belongs_to :scraper

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

    ApiQuery.create!(query: query, scraper_id: scraper.id,
    owner_id: owner.id, utime: (benchmark.cutime + benchmark.utime),
    stime: (benchmark.cstime + benchmark.stime),
    wall_time: benchmark.real, size: size, type: type, format: format)
  end
end
