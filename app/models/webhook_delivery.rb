class WebhookDelivery < ActiveRecord::Base
  belongs_to :webhook
  belongs_to :run
end
