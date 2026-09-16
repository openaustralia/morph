# typed: false
# frozen_string_literal: true

require "spec_helper"

# A thin client for the handful of GitLab API v4 calls morph.io makes. The
# `gitlab` gem needs Ruby 3.1, so this is hand-rolled over Faraday, which
# the bundle already has.
describe Morph::GitlabClient, :webmock do
  let(:client) { described_class.new(access_token: "tok") }
  let(:api) { "https://gitlab.com/api/v4" }

  def json(body, status: 200, headers: {})
    { status: status, body: body.to_json, headers: { "Content-Type" => "application/json" }.merge(headers) }
  end

  it "sends the token as a bearer token" do
    stub = stub_request(:get, "#{api}/user").with(headers: { "Authorization" => "Bearer tok" }).to_return(json({ id: 1, username: "alice" }))

    client.current_user

    expect(stub).to have_been_requested
  end

  it "follows GITLAB_URL for self-hosted instances" do
    allow(Morph::Environment).to receive(:gitlab_url).and_return("https://git.example.org")
    stub = stub_request(:get, "https://git.example.org/api/v4/user").to_return(json({ id: 1, username: "alice" }))

    described_class.new(access_token: "tok").current_user

    expect(stub).to have_been_requested
  end

  describe "#project" do
    it "fetches a project by its path" do
      stub_request(:get, "#{api}/projects/alice%2Fplanning")
        .to_return(json({ id: 7, path: "planning", path_with_namespace: "alice/planning", description: "d", visibility: "private",
                          default_branch: "main", web_url: "https://gitlab.com/alice/planning", http_url_to_repo: "https://gitlab.com/alice/planning.git",
                          namespace: { id: 3, path: "alice", kind: "user" } }))

      project = client.project("alice/planning")

      expect(project).to have_attributes(id: 7, path: "planning", full_path: "alice/planning", private: true, default_branch: "main",
                                         web_url: "https://gitlab.com/alice/planning", http_url_to_repo: "https://gitlab.com/alice/planning.git")
      expect(project.namespace).to have_attributes(id: 3, path: "alice", group: false)
    end

    it "returns nil for a project that cannot be seen" do
      stub_request(:get, "#{api}/projects/alice%2Fsecret").to_return(json({ message: "404 Project Not Found" }, status: 404))

      expect(client.project("alice/secret")).to be_nil
    end

    it "raises on anything other than 404" do
      stub_request(:get, "#{api}/projects/alice%2Fplanning").to_return(json({ message: "401 Unauthorized" }, status: 401))

      expect { client.project("alice/planning") }.to raise_error(Morph::GitlabClient::Unauthorized)
    end
  end

  describe "#members" do
    it "lists everyone with access, inherited members included, by username and access level" do
      stub_request(:get, "#{api}/projects/7/members/all").with(query: { per_page: 100, page: 1 })
                                                         .to_return(json([{ id: 1, username: "alice", access_level: 50 }, { id: 2, username: "bob", access_level: 30 }]))

      members = client.members(7)

      expect(members.map { |m| [m.username, m.access_level] }).to eq([["alice", 50], ["bob", 30]])
    end

    it "walks pagination" do
      stub_request(:get, "#{api}/projects/7/members/all").with(query: { per_page: 100, page: 1 })
                                                         .to_return(json([{ id: 1, username: "alice", access_level: 50 }], headers: { "X-Next-Page" => "2" }))
      stub_request(:get, "#{api}/projects/7/members/all").with(query: { per_page: 100, page: 2 })
                                                         .to_return(json([{ id: 2, username: "bob", access_level: 30 }], headers: { "X-Next-Page" => "" }))

      expect(client.members(7).map(&:username)).to eq(%w[alice bob])
    end
  end

  describe "listing repositories" do
    it "lists a user's own projects, most recently active first" do
      stub_request(:get, "#{api}/users/3/projects").with(query: hash_including("order_by" => "last_activity_at", "per_page" => "100"))
                                                   .to_return(json([{ id: 7, path: "planning", path_with_namespace: "alice/planning", visibility: "public", default_branch: "main",
                                                                      web_url: "u", http_url_to_repo: "h", namespace: { id: 3, path: "alice", kind: "user" } }]))

      expect(client.user_projects(3).map(&:full_path)).to eq(["alice/planning"])
    end

    it "lists a group's projects" do
      stub_request(:get, "#{api}/groups/9/projects").with(query: hash_including("per_page" => "100"))
                                                    .to_return(json([{ id: 8, path: "p", path_with_namespace: "acme/p", visibility: "public", default_branch: "main",
                                                                       web_url: "u", http_url_to_repo: "h", namespace: { id: 9, path: "acme", kind: "group" } }]))

      expect(client.group_projects(9).map(&:full_path)).to eq(["acme/p"])
    end
  end

  describe "#create_project" do
    it "creates a project in the user's namespace with a README so the default branch exists" do
      stub = stub_request(:post, "#{api}/projects")
             .with(body: hash_including("path" => "planning", "description" => "d", "visibility" => "public", "initialize_with_readme" => true))
             .to_return(json({ id: 7, path: "planning", path_with_namespace: "alice/planning", visibility: "public", default_branch: "main",
                               web_url: "u", http_url_to_repo: "h", namespace: { id: 3, path: "alice", kind: "user" } }, status: 201))

      project = client.create_project(path: "planning", description: "d", private: false, namespace_id: nil)

      expect(stub).to have_been_requested
      expect(project.id).to eq(7)
    end

    it "creates a project in a group when a namespace is given" do
      stub = stub_request(:post, "#{api}/projects").with(body: hash_including("namespace_id" => 9, "visibility" => "private"))
                                                   .to_return(json({ id: 8, path: "p", path_with_namespace: "acme/p", visibility: "private", default_branch: "main",
                                                                     web_url: "u", http_url_to_repo: "h", namespace: { id: 9, path: "acme", kind: "group" } }, status: 201))

      client.create_project(path: "p", description: nil, private: true, namespace_id: 9)

      expect(stub).to have_been_requested
    end
  end

  it "commits several files at once" do
    stub = stub_request(:post, "#{api}/projects/7/repository/commits")
           .with(body: hash_including("branch" => "main", "commit_message" => "Add files",
                                      "actions" => [{ "action" => "create", "file_path" => "scraper.rb", "content" => "puts 1" }]))
           .to_return(json({ id: "abc" }, status: 201))

    client.commit_files(7, branch: "main", message: "Add files", files: { "scraper.rb" => "puts 1" })

    expect(stub).to have_been_requested
  end

  it "changes a project's visibility" do
    stub = stub_request(:put, "#{api}/projects/7").with(body: hash_including("visibility" => "private")).to_return(json({ id: 7 }))

    client.set_visibility(7, private: true)

    expect(stub).to have_been_requested
  end

  describe "groups" do
    it "lists the groups the current user belongs to, top-level only" do
      stub_request(:get, "#{api}/groups").with(query: hash_including("min_access_level" => "10", "top_level_only" => "true"))
                                         .to_return(json([{ id: 9, path: "acme", full_path: "acme", name: "Acme", web_url: "https://gitlab.com/groups/acme", avatar_url: nil, description: nil }]))

      groups = client.groups

      expect(groups.first).to have_attributes(id: 9, path: "acme", name: "Acme")
    end

    it "fetches one group" do
      stub_request(:get, "#{api}/groups/acme").to_return(json({ id: 9, path: "acme", full_path: "acme", name: "Acme", web_url: "w", avatar_url: "a", description: "d" }))

      expect(client.group("acme")).to have_attributes(id: 9, avatar_url: "a")
    end
  end

  describe "tokens" do
    it "creates a group access token as a Reporter that can read the API and repositories" do
      stub = stub_request(:post, "#{api}/groups/9/access_tokens")
             .with(body: hash_including("name" => "morph.io", "access_level" => 20, "scopes" => %w[read_api read_repository]))
             .to_return(json({ id: 1, token: "glpat-x", expires_at: "2027-01-01" }, status: 201))

      token = client.create_group_access_token(9, name: "morph.io", expires_at: Date.new(2027, 1, 1))

      expect(stub).to have_been_requested
      expect(token).to have_attributes(token: "glpat-x")
      expect(token.expires_at).to eq(Date.new(2027, 1, 1))
    end

    it "rotates a group access token" do
      stub = stub_request(:post, "#{api}/groups/9/access_tokens/5/rotate").with(body: hash_including("expires_at" => "2027-01-01"))
                                                                          .to_return(json({ id: 6, token: "glpat-y", expires_at: "2027-01-01" }))

      token = client.rotate_group_access_token(9, 5, expires_at: Date.new(2027, 1, 1))

      expect(stub).to have_been_requested
      expect(token).to have_attributes(id: 6, token: "glpat-y")
    end

    it "reports a group access token being unavailable on this plan as Forbidden" do
      stub_request(:post, "#{api}/groups/9/access_tokens").to_return(json({ message: "403 Forbidden" }, status: 403))

      expect { client.create_group_access_token(9, name: "morph.io", expires_at: Date.tomorrow) }.to raise_error(Morph::GitlabClient::Forbidden)
    end

    it "creates a project deploy token that can only clone" do
      stub = stub_request(:post, "#{api}/projects/7/deploy_tokens")
             .with(body: hash_including("name" => "morph.io", "scopes" => ["read_repository"]))
             .to_return(json({ id: 1, username: "gitlab+deploy-token-1", token: "dt", expires_at: nil }, status: 201))

      token = client.create_project_deploy_token(7, name: "morph.io")

      expect(stub).to have_been_requested
      expect(token).to have_attributes(username: "gitlab+deploy-token-1", token: "dt")
    end
  end
end
