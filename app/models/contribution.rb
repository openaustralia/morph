# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: contributions
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  updated_at :datetime
#  scraper_id :integer
#  user_id    :integer
#
# Indexes
#
#  index_contributions_on_scraper_id  (scraper_id)
#  index_contributions_on_user_id     (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#

# Contribution of a user to the code a scraper
class Contribution < ApplicationRecord
  belongs_to :user
  belongs_to :scraper
end
