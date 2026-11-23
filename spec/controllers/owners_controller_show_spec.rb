# typed: false
# frozen_string_literal: true

require "spec_helper"

# The email suppression notice on a person's own page when Postal has reported their email address as undeliverable.
RSpec.describe OwnersController, "#show", type: :controller do
  render_views

  let(:user) { create(:user, nickname: "alice", email: "alice@example.org") }

  def show_page_as(viewer)
    sign_in viewer if viewer
    get :show, params: { id: user.to_param }
    response.body
  end

  context "when the address is suppressed" do
    before { EmailSuppression.suppress!("alice@example.org", reason: :hard_bounce, at: Time.zone.parse("2026-11-01 10:00")) }

    it "tells the person alerts are paused, since when, and how to resume" do
      body = show_page_as(user)

      expect(body).to include("Emails to this address have been returning as undeliverable since 1 November 2026")
      expect(body).to include("alerts are paused")
      expect(body).to include("change your primary email on GitHub")
    end

    it "does not show it to other people, because it says something about someone's email address" do
      expect(show_page_as(create(:user))).not_to include("undeliverable")
    end

    it "does not show it to people who aren't signed in" do
      expect(show_page_as(nil)).not_to include("undeliverable")
    end
  end

  it "shows nothing when the address isn't suppressed" do
    expect(show_page_as(user)).not_to include("undeliverable")
  end
end
