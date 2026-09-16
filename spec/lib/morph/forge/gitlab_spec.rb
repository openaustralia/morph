# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::Forge::Gitlab do
  let(:forge) { described_class.new }
  let(:owner) do
    user = create(:user, nickname: "alice")
    user.forge_identities.create!(forge_key: "gitlab", uid: "42", login: "alice", access_token: "tok")
    user
  end
  let(:scraper) do
    build(:scraper, owner: owner, name: "planning", forge_key: "gitlab", repo_url: "https://gitlab.com/alice/planning",
                    git_url: "https://gitlab.com/alice/planning.git", forge_repo_id: 7)
  end

  it_behaves_like "a forge"

  it "is only available once a GitLab application is configured" do
    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(false)
    expect(forge).not_to be_available

    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(true)
    expect(forge).to be_available
  end

  it "links to the owner's GitLab profile" do
    expect(forge.owner_url(owner)).to eq("https://gitlab.com/alice")
  end

  it "links to a file with GitLab's /-/blob path" do
    allow(scraper).to receive(:default_branch).and_return("main")
    expect(forge.file_url(scraper, "scraper.rb")).to eq("https://gitlab.com/alice/planning/-/blob/main/scraper.rb")
  end

  it "links to a commit with GitLab's /-/commit path" do
    expect(forge.commit_url(scraper, "abc1234")).to eq("https://gitlab.com/alice/planning/-/commit/abc1234")
  end

  it "follows GITLAB_URL for a self-hosted instance" do
    allow(Morph::Environment).to receive(:gitlab_url).and_return("https://git.example.org")

    expect(forge.owner_url(owner)).to eq("https://git.example.org/alice")
  end

  describe "#refresh_tokens", :webmock do
    before do
      allow(Morph::Environment).to receive_messages(gitlab_app_id: "app", gitlab_app_secret: "secret")
    end

    it "trades the refresh token for a new pair and their expiry" do
      stub_request(:post, "https://gitlab.com/oauth/token")
        .with(body: hash_including("grant_type" => "refresh_token", "refresh_token" => "old"), basic_auth: %w[app secret])
        .to_return(status: 200, headers: { "Content-Type" => "application/json" },
                   body: { access_token: "new", refresh_token: "new-refresh", token_type: "bearer", expires_in: 7200, created_at: Time.now.to_i }.to_json)

      tokens = forge.refresh_tokens("old")

      expect(tokens).to have_attributes(access_token: "new", refresh_token: "new-refresh")
      expect(tokens.expires_at).to be_within(10.seconds).of(2.hours.from_now)
    end
  end
end
