# Progress in morp creating a scraper
class CreateScraperProgress < ActiveRecord::Base
  include Sync::Actions
  has_one :scraper, dependent: :nullify

  def update(message, progress)
    update_attributes(message: message, progress: progress)
    sync_update scraper
  end

  def finished
    destroy
    sync_update scraper
  end
end
