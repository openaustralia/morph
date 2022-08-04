# typed: false
# frozen_string_literal: true

class WebhookDelivery < ApplicationRecord
  SUCCESSFUL_STATUSES = (200..299).freeze

  belongs_to :webhook
  belongs_to :run

  def success?
    SUCCESSFUL_STATUSES.include?(response_code)
  end
end
