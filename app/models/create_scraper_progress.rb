# typed: false
# frozen_string_literal: true

# Progress in morp creating a scraper
class CreateScraperProgress < ApplicationRecord
  include RenderSync::Actions
  has_one :scraper, dependent: :nullify

  def update_progress(message, progress)
    update(message: message, progress: progress)
    sync_update scraper
  end

  def finished
    destroy
    sync_update scraper
  end
end
