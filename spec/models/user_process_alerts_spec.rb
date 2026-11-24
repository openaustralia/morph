# typed: false
# frozen_string_literal: true

require "spec_helper"

# Alerts when the person's email address has hard-bounced in Postal. Addresses are fictional.
describe User, "#process_alerts" do
  let(:user) { create(:user, nickname: "alice", email: "Alice@Example.org") }
  let(:watched) { create(:scraper) }
  let(:deliveries) { ActionMailer::Base.deliveries }
  let(:broken) do
    mock_model(Scraper, to_param: "someone/broken", full_name: "someone/broken", latest_successful_run_time: 3.days.ago,
                        last_run: mock_model(Run, finished_at: 2.hours.ago, scraper: nil, error_text: "boom\n"))
  end

  before do
    user.watch(watched)
    allow(user).to receive_messages(watched_broken_scrapers_ordered_by_urgency: [broken], watched_successful_scrapers: [])
  end

  it "sends the alert when the address isn't suppressed" do
    expect { user.process_alerts }.to change(deliveries, :count).by(1)
  end

  it "sends nothing, whatever the case of the address" do
    EmailSuppression.suppress!("alice@example.org", reason: :hard_bounce)

    expect { user.process_alerts }.not_to change(deliveries, :count)
  end

  it "keeps the person's alerts, so they resume if the address changes" do
    EmailSuppression.suppress!("alice@example.org", reason: :hard_bounce)
    user.process_alerts

    expect(user.alerts.count).to eq 1
  end

  it "sends again once the person has a different address" do
    EmailSuppression.suppress!("alice@example.org", reason: :hard_bounce)
    user.update!(email: "alice@example.net")

    expect { user.process_alerts }.to change(deliveries, :count).by(1)
  end

  it "sends again once staff clear the suppression" do
    EmailSuppression.suppress!("alice@example.org", reason: :hard_bounce)
    EmailSuppression.lift!("alice@example.org")

    expect { user.process_alerts }.to change(deliveries, :count).by(1)
  end

  it "gives the notice details while suppressed and none otherwise" do
    expect(user.email_suppression).to be_nil
    EmailSuppression.suppress!("alice@example.org", reason: :hard_bounce, at: Time.zone.parse("2026-11-01 10:00"))

    expect(user.email_suppression.suppressed_at).to eq Time.zone.parse("2026-11-01 10:00")
  end
end
