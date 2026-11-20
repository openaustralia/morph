# typed: false
# frozen_string_literal: true

require "spec_helper"

# Postal's published keys are served through WebMock, so nothing contacts Postal. The addresses are fictional.
RSpec.describe "Postal delivery webhook", :webmock, type: :request do
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:jwks_url) { Rails.configuration.x.postal_jwks_url }
  let(:recipient) { "someone@example.org" }

  def b64(integer)
    Base64.urlsafe_encode64(integer.to_s(2), padding: false)
  end

  def jwk(key, **extra)
    { kty: "RSA", n: b64(key.n), e: b64(key.e) }.merge(extra)
  end

  def stub_jwks(*jwks, status: 200)
    stub_request(:get, jwks_url).to_return(status: status, body: { keys: jwks }.to_json)
  end

  def sign(body, key: private_key)
    Base64.strict_encode64(key.sign(OpenSSL::Digest.new("SHA256"), body))
  end

  def post_event(body, signature: sign(body))
    headers = { "CONTENT_TYPE" => "application/json" }
    headers["X-Postal-Signature-256"] = signature if signature
    post "/postal/event", params: body, headers: headers
  end

  def message(tag: "alert", to: recipient)
    { id: 1, token: "abc", direction: "outgoing", to: to, from: "contact@morph.io", tag: tag }
  end

  def status_event(event: "MessageDeliveryFailed", output: "550 5.1.1 No such user", details: "Hard fail",
                   tag: "alert", to: recipient, timestamp: nil)
    { event: event, uuid: "0f6f76ec", timestamp: timestamp,
      payload: { status: "HardFail", details: details, output: output, message: message(tag: tag, to: to) } }
      .compact.to_json
  end

  def bounce_event(tag: "alert", to: recipient)
    { event: "MessageBounced", uuid: "0f6f76ed",
      payload: { original_message: message(tag: tag, to: to), bounce: { id: 2, direction: "incoming", tag: nil } } }.to_json
  end

  before { stub_jwks(jwk(private_key)) }

  describe "a hard failure" do
    it "suppresses the address and answers 200" do
      post_event(status_event)

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.active.count).to eq 1
      expect(EmailSuppression.active.first).to have_attributes(
        address: recipient, reason: "hard_bounce", postal_event: "MessageDeliveryFailed",
        reply_excerpt: "550 5.1.1 No such user"
      )
    end

    it "suppresses at once on a bounce report, reading the recipient from original_message" do
      post_event(bounce_event)

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.suppressed?(recipient)).to be true
    end

    it "treats the address as the same whatever its case or display name" do
      post_event(status_event(to: "Some One <Someone@Example.org>"))

      expect(EmailSuppression.suppressed?("someone@example.org")).to be true
    end

    it "keeps one row when the same failure arrives twice" do
      2.times { post_event(status_event) }

      expect(EmailSuppression.where(address: recipient).count).to eq 1
    end

    it "suppresses again after a lift when the address hard-bounces again" do
      post_event(status_event)
      EmailSuppression.lift!(recipient)
      post_event(status_event)

      expect(EmailSuppression.suppressed?(recipient)).to be true
      expect(EmailSuppression.where(address: recipient).count).to eq 1
    end
  end

  describe "a reply the database can't store as it is" do
    it "still suppresses the address, replacing characters outside the Basic Multilingual Plane" do
      post_event(status_event(output: "550 5.1.1 No such user \u{1F4A9}"))

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.active.first.reply_excerpt).to eq "550 5.1.1 No such user ?"
    end
  end

  describe "a recipient that isn't an address" do
    it "answers 200 and suppresses nothing" do
      post_event(status_event(to: "<>"))

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.count).to eq 0
    end
  end

  describe "a signed body we can't read" do
    it "answers 200 so Postal doesn't retry it, and suppresses nothing" do
      ["not json", "[1, 2]"].each { |body| post_event(body) }

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.count).to eq 0
    end
  end

  describe "failures that say nothing about the address" do
    it "ignores a 5.7.x refusal" do
      post_event(status_event(output: "550 5.7.1 Our system has detected that this message is suspicious"))

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.count).to eq 0
    end

    it "ignores a 5.7.x refusal with leading whitespace" do
      post_event(status_event(output: " 550 5.7.1 Service unavailable, client host blocked"))

      expect(EmailSuppression.count).to eq 0
    end

    it "ignores a hyphenated 5.7.x refusal" do
      post_event(status_event(output: "550-5.7.26 Unauthenticated sender"))

      expect(EmailSuppression.count).to eq 0
    end

    it "ignores a failure after retries ran out" do
      post_event(status_event(output: nil, details: "Maximum number of delivery attempts (18) reached"))

      expect(EmailSuppression.count).to eq 0
    end

    it "ignores a failure because the raw message was removed" do
      post_event(status_event(output: nil, details: "Raw message has been removed"))

      expect(EmailSuppression.count).to eq 0
    end
  end

  describe "events and mail to ignore" do
    it "ignores delayed and held events" do
      %w[MessageDelayed MessageHeld].each { |event| post_event(status_event(event: event)) }

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.count).to eq 0
    end

    it "ignores an event type it doesn't know" do
      post_event({ event: "DomainDNSError", payload: { domain: "example.org" } }.to_json)

      expect(response).to have_http_status(:ok)
    end

    it "ignores untagged mail, such as Discourse mail from the same mail server" do
      post_event(status_event(tag: nil))

      expect(response).to have_http_status(:ok)
      expect(EmailSuppression.count).to eq 0
    end

    it "ignores mail with a tag we didn't set" do
      post_event(status_event(tag: "discourse"))

      expect(EmailSuppression.count).to eq 0
    end
  end

  describe "the signature" do
    it "answers 403 for a signature from some other key" do
      body = status_event
      post_event(body, signature: sign(body, key: OpenSSL::PKey::RSA.new(2048)))

      expect(response).to have_http_status(:forbidden)
      expect(EmailSuppression.count).to eq 0
    end

    it "answers 403 for an unsigned request, without fetching the keys" do
      post_event(status_event, signature: nil)

      expect(response).to have_http_status(:forbidden)
      expect(a_request(:get, jwks_url)).not_to have_been_made
    end

    it "answers 403 when the body was changed after signing" do
      body = status_event
      post_event(body.sub("someone@", "other@"), signature: sign(body))

      expect(response).to have_http_status(:forbidden)
    end

    it "accepts a signature from any of the published keys" do
      stub_jwks(jwk(OpenSSL::PKey::RSA.new(2048)), jwk(private_key))
      post_event(status_event)

      expect(EmailSuppression.suppressed?(recipient)).to be true
    end

    it "answers 503 so Postal retries when the keys can't be fetched" do
      stub_jwks(status: 502)
      post_event(status_event)

      expect(response).to have_http_status(:service_unavailable)
      expect(EmailSuppression.count).to eq 0
    end
  end
end
