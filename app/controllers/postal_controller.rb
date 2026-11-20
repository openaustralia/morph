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

    body = T.cast(JSON.parse(request.raw_post), T::Hash[String, T.untyped])
    event_name = body["event"]
    payload = body["payload"]
    # Delayed, held and every other event are accepted and ignored. Postal keeps retrying soft failures itself.
    return head :ok unless HARD_FAILURE_EVENTS.include?(event_name) && payload.is_a?(Hash)

    suppress_if_hard_bounce(T.cast(event_name, String), payload)
    head :ok
  end

  private

  # A bounce report wraps the message that bounced in original_message.
  sig { params(event: String, payload: T::Hash[String, T.untyped]).void }
  def suppress_if_hard_bounce(event, payload)
    message = payload[event == "MessageBounced" ? "original_message" : "message"]
    recipient = message["to"] if message.is_a?(Hash)
    return log(event, "ignored: untagged") if recipient.blank? || message["tag"] != PostalWebhook::ALERT_TAG
    return log(event, "ignored: not about the address") if event == "MessageDeliveryFailed" && !address_failed?(payload)

    EmailSuppression.suppress!(recipient, reason: :hard_bounce, postal_event: event, reply: payload["output"])
    log(event, "suppressed")
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
