class Webhook < ActiveRecord::Base
  belongs_to :scraper
  has_many :deliveries, class_name: WebhookDelivery
  validates :url, presence: true

  def last_delivery
    deliveries.order(created_at: :desc).first
  end
end
