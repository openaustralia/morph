class WebhookDelivery < ActiveRecord::Base
  SUCCESSFUL_STATUSES = 200..299

  belongs_to :webhook
  belongs_to :run

  def success?
    SUCCESSFUL_STATUSES.include?(response_code)
  end
end
