# typed: false
# frozen_string_literal: true

require "spec_helper"

describe RotateForgeCredentialWorker do
  let(:org) do
    o = create(:organization, :forgeless, nickname: "acme")
    o.forge_identities.create!(forge_key: "gitlab", uid: "9", login: "acme")
    o
  end
  let(:client) { instance_double(Morph::GitlabClient) }

  it "rotates the group access token in place, keeping the same row" do
    credential = org.forge_credentials.create!(kind: "group_access_token", token: "old", expires_at: 2.weeks.from_now, forge_token_id: "5")
    allow(Morph::GitlabClient).to receive(:new).with(access_token: "old").and_return(client)
    allow(client).to receive(:rotate_group_access_token).with(9, 5, expires_at: an_instance_of(Date))
                                                        .and_return(Morph::GitlabClient::Token.new(id: 6, token: "new", username: nil, expires_at: Time.zone.today + 364))

    described_class.new.perform(credential.id)

    expect(credential.reload).to have_attributes(token: "new", forge_token_id: "6")
    expect(credential.expires_at.to_date).to eq(Time.zone.today + 364)
  end

  it "leaves deploy tokens alone, since they do not expire" do
    credential = org.forge_credentials.create!(kind: "deploy_token", token: "dt", username: "u")
    allow(Morph::GitlabClient).to receive(:new)

    described_class.new.perform(credential.id)

    expect(Morph::GitlabClient).not_to have_received(:new)
  end
end
