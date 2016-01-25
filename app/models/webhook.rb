class Webhook < ActiveRecord::Base
  belongs_to :scraper
  # TODO: has_many :deliveries, class_name: WebhookDeliveries
end
