# typed: false
# frozen_string_literal: true

require "spec_helper"

describe PostalWebhook::SigningKeys, :webmock do
  let(:signing_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:jwks_url) { Rails.configuration.x.postal_jwks_url }

  def b64(integer)
    Base64.urlsafe_encode64(integer.to_s(2), padding: false)
  end

  def jwk(key, **extra)
    { "kty" => "RSA", "n" => b64(key.n), "e" => b64(key.e), "use" => "sig" }.merge(extra.transform_keys(&:to_s)).compact
  end

  def stub_jwks(body:, code: 200)
    stub_request(:get, jwks_url).to_return(status: code, body: body)
  end

  def pems
    described_class.call&.map(&:to_pem)
  end

  before { allow(Sentry).to receive(:capture_exception) }

  it "returns the key Postal publishes" do
    stub_jwks(body: { keys: [jwk(signing_key.public_key)] }.to_json)

    expect(pems).to eq [signing_key.public_key.to_pem]
  end

  it "returns every signing key, so a rotation in progress still verifies" do
    other = OpenSSL::PKey::RSA.new(2048)
    stub_jwks(body: { keys: [jwk(other.public_key), jwk(signing_key.public_key)] }.to_json)

    expect(pems).to eq [other.public_key.to_pem, signing_key.public_key.to_pem]
  end

  it "ignores a key that isn't for signatures" do
    stub_jwks(body: { keys: [jwk(signing_key.public_key, use: "enc")] }.to_json)

    expect(pems).to be_nil
  end

  it "accepts a key with no use, which the format allows" do
    stub_jwks(body: { keys: [jwk(signing_key.public_key, use: nil)] }.to_json)

    expect(pems).to eq [signing_key.public_key.to_pem]
  end

  it "ignores a key that isn't RSA" do
    stub_jwks(body: { keys: [{ "kty" => "oct", "k" => "c2VjcmV0", "use" => "sig" }] }.to_json)

    expect(pems).to be_nil
  end

  [
    ["a non-200", { body: "{}", code: 502 }],
    ["a body that isn't JSON", { body: "<html>Bad gateway</html>" }],
    ["a body that isn't an object", { body: "[1, 2]" }],
    ["no keys member", { body: { foo: "bar" }.to_json }],
    ["a keys member that isn't a list", { body: { keys: "nope" }.to_json }],
    ["a malformed modulus", { body: { keys: [{ "kty" => "RSA", "n" => "!!!!", "e" => "AQAB" }] }.to_json }]
  ].each do |description, stub|
    it "returns nil and reports to Sentry for #{description}" do
      stub_jwks(**stub)

      expect(pems).to be_nil
      expect(Sentry).to have_received(:capture_exception).with(described_class::FetchError, anything)
    end
  end

  it "returns nil and reports to Sentry when Postal can't be reached" do
    stub_request(:get, jwks_url).to_timeout

    expect(pems).to be_nil
    expect(Sentry).to have_received(:capture_exception)
  end

  describe "caching" do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }

    before { allow(Rails).to receive(:cache).and_return(cache) }

    it "fetches once for a burst of webhooks" do
      stub_jwks(body: { keys: [jwk(signing_key.public_key)] }.to_json)
      3.times { described_class.call }

      expect(a_request(:get, jwks_url)).to have_been_made.once
    end

    it "caches a failure too, so an outage isn't one outbound request per webhook" do
      stub_jwks(body: "nope", code: 500)
      3.times { described_class.call }

      expect(a_request(:get, jwks_url)).to have_been_made.once
    end
  end
end
