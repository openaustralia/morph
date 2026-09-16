# typed: false
# frozen_string_literal: true

require "spec_helper"

# GitLab access tokens expire after two hours and the refresh token is
# rotated on every use (ADR 0007), so refreshing has to be serialised.
describe ForgeIdentity, "#fresh_access_token" do
  let(:owner) { create(:user) }
  let(:forge) { instance_double(Morph::Forge::Gitlab) }

  before { allow(Morph::Forge).to receive(:for).with("gitlab").and_return(forge) }

  it "hands back the current token when it is not about to expire" do
    identity = owner.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "a", access_token: "live", token_expires_at: 1.hour.from_now)
    allow(forge).to receive(:refresh_tokens)

    expect(identity.fresh_access_token).to eq("live")
    expect(forge).not_to have_received(:refresh_tokens)
  end

  it "hands back the current token when the forge never expires it" do
    identity = owner.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "a", access_token: "forever", token_expires_at: nil)
    allow(forge).to receive(:refresh_tokens)

    expect(identity.fresh_access_token).to eq("forever")
    expect(forge).not_to have_received(:refresh_tokens)
  end

  it "asks the forge for new tokens when the current one is about to expire, and stores them" do
    identity = owner.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "a",
                                              access_token: "old", refresh_token: "old-refresh", token_expires_at: 2.minutes.from_now)
    refreshed = Morph::Forge::Tokens.new(access_token: "new", refresh_token: "new-refresh", expires_at: 2.hours.from_now)
    allow(forge).to receive(:refresh_tokens).with("old-refresh").and_return(refreshed)

    expect(identity.fresh_access_token).to eq("new")
    expect(identity.reload).to have_attributes(access_token: "new", refresh_token: "new-refresh")
    expect(identity.token_expires_at).to be_within(5.seconds).of(2.hours.from_now)
  end

  it "refreshes under a row lock so two workers cannot both spend the same refresh token" do
    identity = owner.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "a",
                                              access_token: "old", refresh_token: "r", token_expires_at: 1.minute.ago)
    refreshed = Morph::Forge::Tokens.new(access_token: "new", refresh_token: "r2", expires_at: 2.hours.from_now)
    allow(forge).to receive(:refresh_tokens).and_return(refreshed)
    allow(identity).to receive(:with_lock).and_call_original

    identity.fresh_access_token

    expect(identity).to have_received(:with_lock)
  end

  it "does not refresh again if another worker already did while it waited for the lock" do
    identity = owner.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "a",
                                              access_token: "old", refresh_token: "r", token_expires_at: 1.minute.ago)
    allow(forge).to receive(:refresh_tokens)
    # Simulate the other worker having finished by the time the lock is taken
    allow(identity).to receive(:with_lock) do |&block|
      described_class.where(id: identity.id).update_all(access_token: "theirs", refresh_token: "r2", token_expires_at: 2.hours.from_now) # rubocop:disable Rails/SkipsModelValidations
      identity.reload
      block.call
    end

    expect(identity.fresh_access_token).to eq("theirs")
    expect(forge).not_to have_received(:refresh_tokens)
  end
end
