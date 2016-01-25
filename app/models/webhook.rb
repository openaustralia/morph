class Webhook < ActiveRecord::Base
  belongs_to :scraper
  has_many :deliveries, class_name: WebhookDelivery
end
