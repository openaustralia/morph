# typed: strict
# frozen_string_literal: true

# Receives Postal's delivery webhooks and suppresses addresses that hard-bounce. Same route and rule as Planning Alerts.
# https://docs.postalserver.io/developer/webhooks
#
# Not a browser, so there is no session or request forgery check.
class PostalController < ActionController::API
  extend T::Sig

  HARD_FAILURE_EVENTS = T.let(%w[MessageDeliveryFailed MessageBounced].freeze, T::Array[String])

  sig { void }
  def event
    failure = signature_failure_status(request.raw_post)
    return head failure if failure

    body = parse_body(request.raw_post)
    # A signed body we can't read won't improve on a retry, so don't ask Postal to send it again
    return head :ok if body.nil?

    event_name = body["event"]
    payload = body["payload"]
    # Delayed, held and every other event are accepted and ignored. Postal keeps retrying soft failures itself.
    return head :ok unless HARD_FAILURE_EVENTS.include?(event_name) && payload.is_a?(Hash)

    suppress_if_hard_bounce(T.cast(event_name, String), payload, event_time(body["timestamp"], payload["timestamp"]))
    head :ok
  end

  private

  sig { params(raw_post: String).returns(T.nilable(T::Hash[String, T.untyped])) }
  def parse_body(raw_post)
    parsed = JSON.parse(raw_post)
    parsed if parsed.is_a?(Hash)
  rescue JSON::ParserError
    nil
  end

  # When Postal says the event happened, which a retry of the event repeats. Status events carry it in the payload and
  # bounce reports in the webhook itself. Nil if it didn't say.
  sig { params(webhook_time: T.untyped, payload_time: T.untyped).returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def event_time(webhook_time, payload_time)
    timestamp = [payload_time, webhook_time].find { |value| value.is_a?(Numeric) }
    Time.zone.at(timestamp) if timestamp
  end

  # A bounce report wraps the message that bounced in original_message.
  sig do
    params(event: String, payload: T::Hash[String, T.untyped], happened_at: T.nilable(ActiveSupport::TimeWithZone)).void
  end
  def suppress_if_hard_bounce(event, payload, happened_at)
    message = payload[event == "MessageBounced" ? "original_message" : "message"]
    recipient = message["to"] if message.is_a?(Hash)
    return log(event, "ignored: untagged") if EmailSuppression.normalise(recipient).blank? || message["tag"] != PostalWebhook::ALERT_TAG
    return log(event, "ignored: not about the address") if event == "MessageDeliveryFailed" && !address_failed?(payload)

    # Postal retries an event it didn't get a 200 for, possibly after staff have lifted the address. That says nothing
    # about the address now, so only a failure after the latest lift suppresses it again.
    return log(event, "ignored: before the address was last lifted") if lifted_since?(recipient, happened_at)

    EmailSuppression.suppress!(recipient, reason: :hard_bounce, postal_event: event, reply: payload["output"],
                                          at: happened_at || Time.zone.now)
    log(event, "suppressed")
  end

  sig { params(address: String, happened_at: T.nilable(ActiveSupport::TimeWithZone)).returns(T::Boolean) }
  def lifted_since?(address, happened_at)
    lifted_at = EmailSuppression.last_lifted_at(address)
    !happened_at.nil? && !lifted_at.nil? && happened_at <= lifted_at
  end

  sig { params(payload: T::Hash[String, T.untyped]).returns(T::Boolean) }
  def address_failed?(payload)
    PostalWebhook::BounceRule.address_failed?(details: payload["details"], output: payload["output"])
  end

  # Event type and outcome only, never an address.
  sig { params(event: String, outcome: String).void }
  def log(event, outcome)
    Rails.logger.info("Postal #{event}: #{outcome}")
  end

  # X-Postal-Signature-256 holds a base64 RSA-SHA256 signature of the raw body, made with Postal's installation-wide
  # key. We check it against every key Postal currently publishes, so a rotation needs no change here.
  #
  # Returns nil when properly signed, otherwise the status to respond with. A bad signature gets 403 and the event is
  # gone for good. Being unable to reach the keys is different: we can't tell whether the request is genuine, so 503
  # asks Postal to retry (about 36 minutes of backoffs) instead of dropping a real event.
  sig { params(raw_post: String).returns(T.nilable(Symbol)) }
  def signature_failure_status(raw_post)
    signature = request.headers["X-Postal-Signature-256"]
    # Checked before the keys are fetched, so an unsigned request costs no outbound request.
    return :forbidden if signature.blank?

    keys = PostalWebhook::SigningKeys.call
    return :service_unavailable if keys.nil?

    decoded = Base64.decode64(signature)
    digest = OpenSSL::Digest.new("SHA256")
    keys.any? { |key| key.verify(digest, decoded, raw_post) } ? nil : :forbidden
  end
end
