# typed: false
# frozen_string_literal: true

require "spec_helper"

describe DeliverWebhookWorker do
  let(:scraper) { create(:scraper) }
  let(:run) do
    create(:run,
           git_revision: "c9fabbc7a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6",
           records_added: 100,
           records_removed: 200,
           status_code: 3,
           started_at: 400.4.seconds.ago,
           finished_at: 0.1.seconds.ago,
           auto: true)
  end

  describe "test to actual site", :vcr do
    it "works" do
      VCR.use_cassette("webhook_delivery") do
        webhook = Webhook.create!(scraper: scraper, url: "http://requestb.in/x3pcr8x3")
        webhook_delivery = webhook.deliveries.create!(run: run)
        described_class.new.perform(webhook_delivery.id)
        webhook_delivery.reload
        expect(webhook_delivery.response_code).to be(200)
        expect(webhook_delivery.sent_at).to be_within(1.minute).of(DateTime.now)
      end
    end
  end

  describe "error handling" do
    it "records response code and time on success" do
      webhook = Webhook.create!(scraper: scraper, url: "http://example.com/hook")
      webhook_delivery = webhook.deliveries.create!(run: run)

      stub_request(:post, "http://example.com/hook").to_return(status: 200)

      described_class.new.perform(webhook_delivery.id)

      webhook_delivery.reload
      expect(webhook_delivery.response_code).to eq(200)
      expect(webhook_delivery.sent_at).to be_within(1.minute).of(DateTime.now)
    end

    it "logs connection failures without raising" do
      webhook = Webhook.create!(scraper: scraper, url: "http://example.com/hook")
      webhook_delivery = webhook.deliveries.create!(run: run)

      stub_request(:post, "http://example.com/hook").to_raise(Faraday::ConnectionFailed.new("Connection refused"))

      allow(Rails.logger).to receive(:error)

      expect do
        described_class.new.perform(webhook_delivery.id)
      end.not_to raise_error

      expect(Rails.logger).to have_received(:error).with(/Webhook delivery failure/)
    end
  end

  describe "URL substitution" do
    it "substitutes all placeholders correctly" do
      substitutions = {
        "ADDED" => run.records_added,
        "AUTO" => run.auto,
        "COMMIT" => run.git_revision,
        "OUTCOME" => "failed",
        "REMOVED" => run.records_removed,
        "REVISION" => "c9fabbc7",
        "RUN_TIME" => run.wall_time.to_i,
        "STATUS_CODE" => run.status_code
      }

      url_template = "https://example.com/?#{substitutions.keys.map { |k| "#{k.downcase}=#{k}" }.join('&')}"
      expected_url = "https://example.com/?#{substitutions.map { |k, v| "#{k.downcase}=#{v}" }.join('&')}"

      webhook = Webhook.create!(scraper: scraper, url: url_template)
      webhook_delivery = webhook.deliveries.create!(run: run)

      stub = stub_request(:post, expected_url).to_return(status: 200)

      described_class.new.perform(webhook_delivery.id)

      expect(stub).to have_been_requested.once
    end

    it "uses 'success' for OUTCOME when run succeeds" do
      run.update!(status_code: 0)
      webhook = Webhook.create!(scraper: scraper, url: "https://example.com/?outcome=OUTCOME")
      webhook_delivery = webhook.deliveries.create!(run: run)

      stub = stub_request(:post, "https://example.com/?outcome=success").to_return(status: 200)

      described_class.new.perform(webhook_delivery.id)

      expect(stub).to have_been_requested.once
    end
  end
end
