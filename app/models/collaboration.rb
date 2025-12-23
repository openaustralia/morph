# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: collaborations
#
#  id         :bigint           not null, primary key
#  admin      :boolean          not null
#  maintain   :boolean          not null
#  pull       :boolean          not null
#  push       :boolean          not null
#  triage     :boolean          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :integer          not null
#  scraper_id :integer          not null
#
# Indexes
#
#  index_collaborations_on_owner_id                 (owner_id)
#  index_collaborations_on_scraper_id               (scraper_id)
#  index_collaborations_on_scraper_id_and_owner_id  (scraper_id,owner_id)
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => owners.id)
#  fk_rails_...  (scraper_id => scrapers.id)
#

# Contribution of a user to the code a scraper
# == Schema Information
#
# Table name: collaborations
#
#  id         :bigint           not null, primary key
#  admin      :boolean          not null
#  maintain   :boolean          not null
#  pull       :boolean          not null
#  push       :boolean          not null
#  triage     :boolean          not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  owner_id   :integer          not null
#  scraper_id :integer          not null
#
# Indexes
#
#  index_collaborations_on_owner_id                 (owner_id)
#  index_collaborations_on_scraper_id               (scraper_id)
#  index_collaborations_on_scraper_id_and_owner_id  (scraper_id,owner_id)
#
# Foreign Keys
#
#  fk_rails_...  (owner_id => owners.id)
#  fk_rails_...  (scraper_id => scrapers.id)
#
class Collaboration < ApplicationRecord
  belongs_to :owner
  belongs_to :scraper
end
