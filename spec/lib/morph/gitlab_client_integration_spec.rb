# typed: false
# frozen_string_literal: true

require "spec_helper"

# Against gitlab.com for real. Needs a group with a public and a private test
# project and a personal access token of a group Owner; see TESTING.md.
# Skips itself when they are not set, like the GitHub App spec does.
describe Morph::GitlabClient, :gitlab_integration do
  let(:group_path) { ENV.fetch("GITLAB_TEST_GROUP", nil) }
  let(:token) { ENV.fetch("GITLAB_TEST_TOKEN", nil) }
  let(:client) { described_class.new(access_token: token) }

  before do
    skip "GITLAB_TEST_GROUP and GITLAB_TEST_TOKEN not set" if group_path.nil? || token.nil?
  end

  it "sees the group" do
    group = client.group(group_path)
    expect(group).to have_attributes(path: group_path.split("/").last)
  end

  it "sees the public test project and reads its visibility" do
    project = client.project("#{group_path}/public-scraper")
    expect(project).to have_attributes(private: false)
    expect(project.default_branch).to be_present
  end

  it "sees the private test project" do
    expect(client.project("#{group_path}/private-scraper")).to have_attributes(private: true)
  end

  it "lists members with their access levels" do
    project = client.project("#{group_path}/public-scraper")
    members = client.members(project.id)
    expect(members.map(&:access_level)).to all(be >= Morph::GitlabClient::GUEST)
  end

  it "cannot see a project that does not exist" do
    expect(client.project("#{group_path}/no-such-project-#{SecureRandom.hex(4)}")).to be_nil
  end

  it "refuses a bad token" do
    expect { described_class.new(access_token: "not-a-token").current_user }.to raise_error(Morph::GitlabClient::Unauthorized)
  end
end
