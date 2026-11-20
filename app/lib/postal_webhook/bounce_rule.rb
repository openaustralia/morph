# typed: strict
# frozen_string_literal: true

module PostalWebhook
  # Decides whether a permanent delivery failure says anything about the recipient's address. Shared by the webhook and
  # the one-off import of past failures, so the two can't drift apart. Same rule as Planning Alerts.
  module BounceRule
    extend T::Sig

    # The receiving server's reply starts with a 5.7.x enhanced status code when it has refused us for a policy or
    # reputation reason, such as a block on our sending IP address. https://www.rfc-editor.org/rfc/rfc3463
    SENDER_SIDE_REFUSAL = T.let(/\A\d{3}[ -]5\.7\.\d+/, Regexp)

    # Postal reports a hard fail with no reply when it runs out of retries after temporary failures.
    RETRIES_EXHAUSTED = T.let(/\AMaximum number of delivery attempts/, Regexp)

    # Postal also hard fails when it can't send a held message because it has already deleted the stored copy.
    RAW_MESSAGE_REMOVED = T.let(/\ARaw message has been removed/, Regexp)

    sig { params(reply: T.nilable(String)).returns(T::Boolean) }
    def self.blames_sender?(reply)
      SENDER_SIDE_REFUSAL.match?(reply.to_s)
    end

    # Whether a MessageDeliveryFailed event says the address itself is bad.
    sig { params(details: T.nilable(String), output: T.nilable(String)).returns(T::Boolean) }
    def self.address_failed?(details:, output:)
      return false if RETRIES_EXHAUSTED.match?(details.to_s) || RAW_MESSAGE_REMOVED.match?(details.to_s)

      !blames_sender?(output)
    end
  end
end
