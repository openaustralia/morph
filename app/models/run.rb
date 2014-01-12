class Run < ActiveRecord::Base
  belongs_to :scraper
  has_many :log_lines
  belongs_to :metric

  def finished?
    !!finished_at
  end

  def finished_successfully?
    finished? && status_code == 0
  end

  def finished_with_errors?
    finished? && status_code != 0
  end
end
