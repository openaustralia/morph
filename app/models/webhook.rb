# typed: strict
# frozen_string_literal: true

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
