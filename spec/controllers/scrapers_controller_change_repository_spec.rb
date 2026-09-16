# typed: false
# frozen_string_literal: true

require "spec_helper"

# Re-pointing a Scraper at a repository on another forge, keeping its URL,
# data, runs and watchers. This is what linking identities exists to enable
# (ADR 0008): OAF moving scrapers from GitHub to GitLab.
describe ScrapersController, "#change_repository", type: :controller do
  let(:owner) do
    u = create(:user, nickname: "alice")
    u.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice", access_token: "tok", token_expires_at: 1.hour.from_now)
    u
  end
  let(:scraper) do
    create(:scraper, owner: owner, name: "planning", full_name: "alice/planning", forge_key: "github", forge_repo_id: 1,
                     repo_url: "https://github.com/alice/planning", git_url: "git://github.com/alice/planning.git")
  end
  let(:person) { instance_double(Morph::Forge::PersonClient) }
  let(:gitlab_project) do
    Morph::Forge::Repository.new(id: 7, name: "planning", full_name: "alice/planning", description: "Moved", private: false, default_branch: "main",
                                 web_url: "https://gitlab.com/alice/planning", clone_url: "https://gitlab.com/alice/planning.git", owner_login: "alice")
  end

  before do
    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(true)
    allow_any_instance_of(Morph::Forge::Gitlab).to receive(:person_client).and_return(person) # rubocop:disable RSpec/AnyInstance
    scraper.collaborations.create!(owner: owner, admin: true, maintain: true, pull: true, push: true, triage: true)
    sign_in owner
  end

  it "re-points the scraper at the new repository, clears the clone and re-syncs, keeping everything else" do
    run = create(:run, scraper: scraper, owner: owner)
    FileUtils.mkdir_p(scraper.repo_path)
    File.write(File.join(scraper.repo_path, "old"), "x")
    allow(person).to receive(:repository).with("alice/planning").and_return(gitlab_project)
    allow(CreateFromForgeWorker).to receive(:perform_async)

    post :change_repository, params: { id: scraper.to_param, forge_key: "gitlab", full_name: "alice/planning" }

    scraper.reload
    expect(scraper).to have_attributes(forge_key: "gitlab", forge_repo_id: 7, repo_url: "https://gitlab.com/alice/planning",
                                       git_url: "https://gitlab.com/alice/planning.git", full_name: "alice/planning")
    expect(scraper.runs).to include(run)
    expect(File.exist?(File.join(scraper.repo_path, "old"))).to be false
    expect(CreateFromForgeWorker).to have_received(:perform_async).with(scraper.id)
    expect(response).to redirect_to(scraper)
    expect(flash[:notice]).to include("GitLab")
  end

  it "refuses a repository whose owner on the new forge is not this scraper's Owner" do
    other = gitlab_project.with(full_name: "bob/planning", owner_login: "bob")
    allow(person).to receive(:repository).with("bob/planning").and_return(other)

    post :change_repository, params: { id: scraper.to_param, forge_key: "gitlab", full_name: "bob/planning" }

    expect(scraper.reload.forge_key).to eq("github")
    expect(flash[:alert]).to include("belongs to bob")
  end

  it "refuses a repository the user cannot see" do
    allow(person).to receive(:repository).and_return(nil)

    post :change_repository, params: { id: scraper.to_param, forge_key: "gitlab", full_name: "alice/missing" }

    expect(scraper.reload.forge_key).to eq("github")
    expect(flash[:alert]).to include("could not find")
  end

  it "is only for scraper admins" do
    scraper.collaborations.update_all(admin: false) # rubocop:disable Rails/SkipsModelValidations
    bystander = create(:user)
    sign_in bystander

    expect { post :change_repository, params: { id: scraper.to_param, forge_key: "gitlab", full_name: "alice/planning" } }
      .to raise_error(ActiveRecord::RecordNotFound)

    expect(scraper.reload.forge_key).to eq("github")
  end
end
