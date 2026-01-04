# typed: strict
# frozen_string_literal: true

# Webhook to be called when a scraper runs
#
# == Schema Information
#
# Table name: webhooks
#
#  id         :integer          not null, primary key
#  url        :string(255)
#  created_at :datetime
#  updated_at :datetime
#  scraper_id :integer
#
# Indexes
#
#  index_webhooks_on_scraper_id          (scraper_id)
#  index_webhooks_on_scraper_id_and_url  (scraper_id,url) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (scraper_id => scrapers.id)
#

class Webhook < ApplicationRecord
  extend T::Sig

  belongs_to :scraper
  has_many :deliveries, class_name: "WebhookDelivery", dependent: :delete_all
  validates :url, presence: true, url: true, uniqueness: { scope: :scraper, case_sensitive: true }

  sig { returns(WebhookDelivery) }
  def last_delivery
    deliveries.order(sent_at: :desc).first
  end
end
