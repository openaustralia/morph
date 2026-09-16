# typed: false
# frozen_string_literal: true

require "spec_helper"

# The Organization page's GitLab connection panel (ADR 0007).
RSpec.describe "Connecting an Organization to GitLab", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:org) do
    o = Organization.create!(nickname: "acme")
    o.forge_identities.create!(forge_key: "gitlab", uid: "9", login: "acme")
    o
  end
  let(:member) do
    u = create(:user, :forgeless, nickname: "alice")
    u.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice", access_token: "tok", token_expires_at: 1.hour.from_now)
    org.users << u
    u
  end

  before { allow(Morph::Environment).to receive(:gitlab_configured?).and_return(true) }

  it "shows a member which tier is in force and offers to connect" do
    sign_in member

    get organization_path(org)

    expect(response.body).to include("GitLab access").and include("Connect GitLab group")
  end

  it "shows nothing about it to people who are not members" do
    sign_in create(:user)

    get organization_path(org)

    expect(response.body).not_to include("GitLab access")
  end

  it "connects, reporting the tier reached" do
    sign_in member
    connection = instance_double(Morph::Forge::Gitlab::GroupConnection, connect!: :group_access_token)
    allow(Morph::Forge::Gitlab::GroupConnection).to receive(:new).with(org, member).and_return(connection)

    post connect_gitlab_organization_path(org)

    expect(response).to redirect_to(organization_path(org))
    expect(flash[:notice]).to include("group access token")
  end

  it "refuses to connect for someone who is not a member" do
    sign_in create(:user)

    expect { post connect_gitlab_organization_path(org) }.to raise_error(CanCan::AccessDenied)
  end
end
