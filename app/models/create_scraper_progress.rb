# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: create_scraper_progresses
#
#  id         :integer          not null, primary key
#  heading    :string(255)
#  message    :string(255)
#  progress   :integer
#  created_at :datetime
#  updated_at :datetime
#

# Progress in morp creating a scraper
# == Schema Information
#
# Table name: create_scraper_progresses
#
#  id         :integer          not null, primary key
#  heading    :string(255)
#  message    :string(255)
#  progress   :integer
#  created_at :datetime
#  updated_at :datetime
#
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
