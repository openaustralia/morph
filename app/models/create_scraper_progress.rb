# typed: strict
# frozen_string_literal: true

# Progress in morp creating a scraper
class CreateScraperProgress < ApplicationRecord
  extend T::Sig

  include RenderSync::Actions
  has_one :scraper, dependent: :nullify

  sig { params(message: String, progress: Integer).void }
  def update_progress(message, progress)
    update(message: message, progress: progress)
    sync_update scraper
  end

  sig { void }
  def finished
    destroy
    sync_update scraper
  end
end
