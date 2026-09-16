# typed: false
# frozen_string_literal: true

require "spec_helper"

# Adding a scraper from an existing GitLab project, and creating a new one
# on GitLab, through the same controller actions that serve GitHub.
describe ScrapersController, type: :controller do
  let(:user) do
    u = create(:user, nickname: "alice")
    u.forge_identities.create!(forge_key: "gitlab", uid: "1", login: "alice", access_token: "tok", token_expires_at: 1.hour.from_now)
    u
  end
  let(:person) { instance_double(Morph::Forge::PersonClient) }
  let(:project) do
    Morph::Forge::Repository.new(id: 7, name: "planning", full_name: "alice/planning", description: "Planning applications",
                                 private: false, default_branch: "main", web_url: "https://gitlab.com/alice/planning",
                                 clone_url: "https://gitlab.com/alice/planning.git", owner_login: "alice")
  end

  before do
    allow(Morph::Environment).to receive(:gitlab_configured?).and_return(true)
    allow_any_instance_of(Morph::Forge::Gitlab).to receive(:person_client).with(user.forge_identity("gitlab")).and_return(person) # rubocop:disable RSpec/AnyInstance
    sign_in user
  end

  describe "GET #forge (add from GitLab page)" do
    render_views

    it "renders the picker for GitLab" do
      get :forge, params: { forge_key: "gitlab" }

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Add scraper from your GitLab repository")
    end

    it "is not found for a forge this deployment does not offer" do
      allow(Morph::Environment).to receive(:gitlab_configured?).and_return(false)

      expect { get :forge, params: { forge_key: "gitlab" } }.to raise_error(ActionController::RoutingError)
    end
  end

  describe "GET #forge_form" do
    render_views

    it "lists the user's GitLab projects, marking those already on morph.io" do
      create(:scraper, owner: user, name: "planning", full_name: "alice/planning", forge_key: "gitlab")
      other = project.with(id: 8, name: "other", full_name: "alice/other", web_url: "https://gitlab.com/alice/other")
      allow(person).to receive(:repositories).with(user).and_return([project, other])

      get :forge_form, params: { forge_key: "gitlab", id: user.id }, format: :js

      html = Nokogiri::HTML(response.body)
      expect(html.css("input[type=radio][value='alice/planning'][disabled]")).not_to be_empty
      expect(html.css("input[type=radio][value='alice/other']:not([disabled])")).not_to be_empty
    end
  end

  describe "POST #create_from_forge" do
    it "creates a scraper on GitLab from the chosen project and queues the sync" do
      allow(person).to receive(:repository).with("alice/planning").and_return(project)
      allow(CreateFromForgeWorker).to receive(:perform_async)

      post :create_from_forge, params: { forge_key: "gitlab", scraper: { full_name: "alice/planning" } }

      scraper = Scraper.find_by(full_name: "alice/planning")
      expect(scraper).to have_attributes(forge_key: "gitlab", forge_repo_id: 7, owner: user, description: "Planning applications",
                                         repo_url: "https://gitlab.com/alice/planning", git_url: "https://gitlab.com/alice/planning.git")
      expect(CreateFromForgeWorker).to have_received(:perform_async).with(scraper.id)
      expect(response).to redirect_to(scraper)
    end

    it "puts a group's project under the matching Organization" do
      org = Organization.create!(nickname: "acme")
      org.forge_identities.create!(forge_key: "gitlab", uid: "9", login: "acme")
      org.users << user
      group_project = project.with(full_name: "acme/planning", web_url: "https://gitlab.com/acme/planning", owner_login: "acme")
      allow(person).to receive(:repository).with("acme/planning").and_return(group_project)
      allow(CreateFromForgeWorker).to receive(:perform_async)

      post :create_from_forge, params: { forge_key: "gitlab", scraper: { full_name: "acme/planning" } }

      expect(Scraper.find_by(full_name: "acme/planning").owner).to eq(org)
    end
  end

  describe "POST #create with a GitLab owner" do
    it "records the forge the new repository will be created on" do
      allow(CreateScraperWorker).to receive(:perform_async)

      post :create, params: { scraper: { name: "new_one", owner_id: user.id, original_language_key: "ruby", forge_key: "gitlab" } }

      expect(Scraper.find_by(name: "new_one").forge_key).to eq("gitlab")
      expect(CreateScraperWorker).to have_received(:perform_async)
    end
  end
end
