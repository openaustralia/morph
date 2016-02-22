class Webhook < ActiveRecord::Base
  belongs_to :scraper
  has_many :deliveries, class_name: WebhookDelivery
  validates :url, presence: true, uniqueness: {scope: :scraper, message: "already another webhook with this URL"}

  def last_delivery
    deliveries.order(sent_at: :desc).first
  end
end
