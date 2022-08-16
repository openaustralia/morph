# typed: strict
# frozen_string_literal: true

class DeliverWebhookWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(webhook_delivery_id: Integer).void }
  def perform(webhook_delivery_id)
    webhook_delivery = WebhookDelivery.find(webhook_delivery_id)
    # TODO: As soon as we've upgraded to a recent version of Ubuntu switch the SSL
    # verification back on. It's not crazy-super important that we verify SSL with
    # webhooks but it's sure a good idea.
    connection = Faraday.new(webhook_delivery.webhook.url, ssl: { verify: false })
    response = connection.post
    webhook_delivery.update(
      response_code: response.status,
      sent_at: DateTime.now
    )
  end
end
