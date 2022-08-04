# typed: true
# frozen_string_literal: true

class Webhook < ApplicationRecord
  belongs_to :scraper
  has_many :deliveries, class_name: "WebhookDelivery", dependent: :delete_all
  validates :url, presence: true, url: true, uniqueness: { scope: :scraper, message: "already another webhook with this URL" }

  def last_delivery
    deliveries.order(sent_at: :desc).first
  end
end
