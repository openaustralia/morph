# typed: strict
# frozen_string_literal: true

class WebhookDelivery < ApplicationRecord
  extend T::Sig
  SUCCESSFUL_STATUSES = T.let((200..299).freeze, T::Range[Integer])

  belongs_to :webhook
  belongs_to :run

  sig { returns(T::Boolean) }
  def success?
    SUCCESSFUL_STATUSES.include?(response_code)
  end
end
