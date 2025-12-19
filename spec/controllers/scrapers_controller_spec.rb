# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ScrapersController do
  let(:user) { create(:user, nickname: "mlandauer") }
  let(:organization) do
    o = create(:organization, nickname: "org")
    o.users << user
    o
  end

  describe "#settings" do
    context "when not signed in" do
      it "redirects to sign in page" do
        scraper = create(:scraper, owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
        get :settings, params: { id: scraper.to_param }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "loads the settings page for own scraper" do
        scraper = create(:scraper, owner: user, name: "a_scraper", full_name: "mlandauer/a_scraper")
        get :settings, params: { id: scraper.to_param }
        expect(response).to have_http_status(:success)
      end

      it "raises RecordNotFound when accessing unauthorized scraper settings" do
        other_user = create(:user, nickname: "otheruser")
        scraper = create(:scraper, owner: other_user, name: "a_scraper", full_name: "otheruser/a_scraper")
        expect { get :settings, params: { id: scraper.to_param } }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "#index" do
    it "lists scrapers accessible to anonymous user" do
      create(:scraper, owner: user, name: "public_scraper", full_name: "mlandauer/public_scraper")
      get :index
      expect(response).to have_http_status(:success)
      expect(assigns(:scrapers)).not_to be_nil
    end

    context "when signed in" do
      before { sign_in user }

      it "lists scrapers accessible to current user" do
        create(:scraper, owner: user, name: "my_scraper", full_name: "mlandauer/my_scraper")
        get :index
        expect(response).to have_http_status(:success)
        expect(assigns(:scrapers)).not_to be_nil
      end

      it "supports pagination" do
        get :index, params: { page: 2 }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "#new" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get :new
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "displays the new scraper form" do
        get :new
        expect(response).to have_http_status(:success)
        expect(assigns(:scraper)).to be_a_new(Scraper)
      end
    end
  end

  describe "#create" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post :create, params: { scraper: { name: "test", owner_id: user.id, original_language_key: "ruby" } }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "creates a new scraper and queues worker" do
          scraper_params = {
            name: "new_scraper",
            owner_id: user.id,
            original_language_key: "ruby",
            description: "Test scraper"
          }

          expect do
            post :create, params: { scraper: scraper_params }
          end.to change(Scraper, :count).by(1)

          scraper = Scraper.last
          expect(scraper.name).to eq("new_scraper")
          expect(scraper.owner).to eq(user)
          expect(scraper.full_name).to eq("mlandauer/new_scraper")
          expect(scraper.create_scraper_progress).not_to be_nil
          expect(scraper.collaborations.where(owner: user).first).not_to be_nil
          expect(response).to redirect_to(scraper)
        end

        it "enqueues CreateScraperWorker" do
          scraper_params = {
            name: "worker_test",
            owner_id: user.id,
            original_language_key: "ruby"
          }

          expect(CreateScraperWorker).to receive(:perform_async).with(
            anything,
            user.id,
            anything
          )
          post :create, params: { scraper: scraper_params }
        end

        it "creates collaboration for the creator" do
          scraper_params = {
            name: "collab_test",
            owner_id: user.id,
            original_language_key: "ruby"
          }

          post :create, params: { scraper: scraper_params }
          scraper = Scraper.last
          collab = scraper.collaborations.find_by(owner: user)
          expect(collab).not_to be_nil
          expect(collab.admin).to be true
          expect(collab.maintain).to be true
          expect(collab.pull).to be true
          expect(collab.push).to be true
          expect(collab.triage).to be true
        end
      end

      context "with invalid params" do
        it "re-renders the new template" do
          scraper_params = { name: "", owner_id: user.id }
          post :create, params: { scraper: scraper_params }
          expect(response).to render_template(:new)
          expect(assigns(:scraper)).not_to be_nil
        end
      end
    end
  end

  describe "#github" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get :github
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "displays the github import form" do
        get :github
        expect(response).to have_http_status(:success)
        expect(assigns(:scraper)).to be_a_new(Scraper)
      end
    end
  end

  describe "#github_form" do
    context "when not signed in" do
      it "redirects to sign in page" do
        get :github_form, params: { id: user.id }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "renders the github form partial with repository list" do
        # rubocop:disable RSpec/VerifiedDoubles
        # Using unverified doubles for GitHub API objects because they're external API objects
        # that don't implement methods in a way RSpec verifying doubles can validate
        github_client = double("Octokit::Client")
        repo1 = double(
          "repo1",
          name: "test-repo",
          description: "Test repository",
          full_name: "mlandauer/test-repo",
          rels: double(html: double(href: "https://github.com/mlandauer/test-repo"))
        )
        repo2 = double(
          "repo2",
          name: "another-repo",
          description: "Another repository",
          full_name: "mlandauer/another-repo",
          rels: double(html: double(href: "https://github.com/mlandauer/another-repo"))
        )
        # rubocop:enable RSpec/VerifiedDoubles

        allow_any_instance_of(User).to receive(:github).and_return(github_client)
        allow(github_client).to receive(:public_repos).with("mlandauer").and_return([repo1, repo2])
        allow(controller).to receive(:helpers).and_return(
          double(radio_description: "Description")
        )

        get :github_form, params: { id: user.id }, format: :js

        expect(response).to have_http_status(:success)
        expect(assigns(:scraper)).to be_a_new(Scraper)
        expect(assigns(:owner)).to eq(user)
      end
    end
  end

  describe "#create_github" do
    context "when not signed in" do
      it "redirects to sign in page" do
        post :create_github, params: { scraper: { full_name: "user/repo" } }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid GitHub repository" do
        it "creates scraper from GitHub" do
          allow(Scraper).to receive(:new_from_github).and_return(
            build(:scraper, owner: user, name: "github_scraper", full_name: "mlandauer/github_scraper")
          )
          allow_any_instance_of(Scraper).to receive(:save).and_return(true)
          allow_any_instance_of(Scraper).to receive(:create_create_scraper_progress!)
          allow(CreateFromGithubWorker).to receive(:perform_async)

          post :create_github, params: { scraper: { full_name: "mlandauer/github_scraper" } }

          expect(Scraper).to have_received(:new_from_github).with("mlandauer/github_scraper", user)
          expect(CreateFromGithubWorker).to have_received(:perform_async)
          expect(response).to have_http_status(:redirect)
        end

        it "creates progress record for GitHub import" do
          scraper = build(:scraper, owner: user, name: "progress_test", full_name: "mlandauer/progress_test")
          allow(Scraper).to receive(:new_from_github).and_return(scraper)
          allow(scraper).to receive(:save).and_return(true)
          allow(scraper).to receive(:create_create_scraper_progress!)
          allow(scraper).to receive(:id).and_return(123)
          allow(CreateFromGithubWorker).to receive(:perform_async)

          post :create_github, params: { scraper: { full_name: "mlandauer/progress_test" } }

          expect(scraper).to have_received(:create_create_scraper_progress!).with(
            heading: "Adding from GitHub",
            message: "Queuing",
            progress: 5
          )
        end
      end

      context "with invalid GitHub repository" do
        it "re-renders github template on validation failure" do
          invalid_scraper = build(:scraper, owner: user, name: "", full_name: "mlandauer/")
          allow(Scraper).to receive(:new_from_github).and_return(invalid_scraper)
          allow(invalid_scraper).to receive(:save).and_return(false)

          post :create_github, params: { scraper: { full_name: "mlandauer/invalid" } }

          expect(response).to render_template(:github)
          expect(assigns(:scraper)).to eq(invalid_scraper)
        end
      end
    end
  end

  describe "#show" do
    let(:scraper) { create(:scraper, owner: user, name: "show_test", full_name: "mlandauer/show_test") }

    it "displays public scraper to anonymous user" do
      get :show, params: { id: scraper.to_param }
      expect(response).to have_http_status(:success)
    end

    context "when signed in" do
      before { sign_in user }

      it "displays own scraper" do
        get :show, params: { id: scraper.to_param }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "#destroy" do
    context "when not signed in" do
      it "does not allow you to delete a scraper" do
        create(:scraper, owner: user, name: "a_scraper",
               full_name: "mlandauer/a_scraper")
        delete :destroy, params: { id: "mlandauer/a_scraper" }
        expect(Scraper.count).to eq 1
      end
    end

    context "when signed in" do
      before do
        sign_in user
      end

      context "when you own the scraper" do
        before do
          Scraper.create(owner: user, name: "a_scraper",
                         full_name: "mlandauer/a_scraper")
        end

        it "allows you to delete the scraper" do
          delete :destroy, params: { id: "mlandauer/a_scraper" }
          expect(Scraper.count).to eq 0
        end

        it "redirects to the owning user" do
          delete :destroy, params: { id: "mlandauer/a_scraper" }
          expect(response).to redirect_to user_url(user)
        end
      end

      context "when an organisation you're part of owns the scraper" do
        before do
          Scraper.create(owner: organization, name: "a_scraper",
                         full_name: "org/a_scraper")
        end

        it "allows you to delete a scraper if it's owner by an organisation you're part of" do
          delete :destroy, params: { id: "org/a_scraper" }
          expect(Scraper.count).to eq 0
        end

        it "redirects to the owning organisation" do
          delete :destroy, params: { id: "org/a_scraper" }
          expect(response).to redirect_to organization_url(organization)
        end
      end

      it "does not allow you to delete a scraper if you don't own the scraper" do
        other_user = User.create(nickname: "otheruser")
        Scraper.create(owner: other_user, name: "a_scraper",
                       full_name: "otheruser/a_scraper")
        expect { delete :destroy, params: { id: "otheruser/a_scraper" } }
          .to raise_error(ActiveRecord::RecordNotFound)
        expect(Scraper.count).to eq 1
      end

      it "does not allow you to delete a scraper if it's owner is an organisation your're not part of" do
        other_organisation = Organization.create(nickname: "otherorg")
        Scraper.create(owner: other_organisation, name: "a_scraper",
                       full_name: "otherorg/a_scraper")
        expect { delete :destroy, params: { id: "otherorg/a_scraper" } }
          .to raise_error(ActiveRecord::RecordNotFound)
        expect(Scraper.count).to eq 1
      end
    end
  end

  describe "#update" do
    let(:scraper) { create(:scraper, owner: user, name: "update_test", full_name: "mlandauer/update_test") }

    context "when not signed in" do
      it "redirects to sign in page" do
        patch :update, params: { id: scraper.to_param, scraper: { auto_run: true } }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      context "with valid params" do
        it "updates the scraper and redirects" do
          allow(controller).to receive(:sync_update)
          patch :update, params: { id: scraper.to_param, scraper: { auto_run: true } }

          scraper.reload
          expect(scraper.auto_run).to be true
          expect(controller).to have_received(:sync_update).with(scraper)
          expect(response).to redirect_to(scraper)
          expect(flash[:notice]).to match(/success/i)
        end
      end

      context "with invalid params" do
        it "re-renders settings template" do
          allow_any_instance_of(Scraper).to receive(:update).and_return(false)
          patch :update, params: { id: scraper.to_param, scraper: { auto_run: true } }
          expect(response).to render_template(:settings)
        end
      end
    end
  end

  describe "#run" do
    let(:scraper) { create(:scraper, owner: user, name: "run_test", full_name: "mlandauer/run_test") }

    context "when not signed in" do
      it "redirects to sign in page" do
        post :run, params: { id: scraper.to_param }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "queues the scraper and redirects" do
        scraper # create it first
        allow(controller).to receive(:sync_update)
        allow_any_instance_of(Scraper).to receive(:queue!)

        post :run, params: { id: scraper.to_param }

        expect(controller).to have_received(:sync_update)
        expect(response).to redirect_to(scraper)
      end
    end
  end

  describe "#stop" do
    let(:scraper) { create(:scraper, owner: user, name: "stop_test", full_name: "mlandauer/stop_test") }

    context "when not signed in" do
      it "redirects to sign in page" do
        post :stop, params: { id: scraper.to_param }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "stops the scraper and redirects" do
        scraper # create it first
        allow(controller).to receive(:sync_update)
        allow_any_instance_of(Scraper).to receive(:stop!)

        post :stop, params: { id: scraper.to_param }

        expect(controller).to have_received(:sync_update)
        expect(response).to redirect_to(scraper)
      end
    end
  end

  describe "#clear" do
    let(:scraper) { create(:scraper, owner: user, name: "clear_test", full_name: "mlandauer/clear_test") }

    context "when not signed in" do
      it "redirects to sign in page" do
        post :clear, params: { id: scraper.to_param }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "clears the scraper database and reindexes" do
        scraper # create it first
        # rubocop:disable RSpec/VerifiedDoubles
        # Using unverified double for Database because it's a dynamic object
        # that doesn't have a fixed class interface we can verify against
        database = double("Database")
        # rubocop:enable RSpec/VerifiedDoubles
        allow_any_instance_of(Scraper).to receive(:database).and_return(database)
        allow(database).to receive(:clear)
        allow_any_instance_of(Scraper).to receive(:reindex)

        post :clear, params: { id: scraper.to_param }

        expect(database).to have_received(:clear)
        expect(response).to redirect_to(scraper)
      end
    end
  end

  describe "#watch" do
    let(:scraper) { create(:scraper, owner: user, name: "watch_test", full_name: "mlandauer/watch_test") }

    context "when not signed in" do
      it "redirects to sign in page" do
        post :watch, params: { id: scraper.to_param }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in" do
      before { sign_in user }

      it "toggles watch status for the scraper" do
        scraper # create it first
        allow_any_instance_of(User).to receive(:toggle_watch)

        post :watch, params: { id: scraper.to_param }

        expect(response).to redirect_to(root_path)
      end

      it "redirects back to referrer if available" do
        scraper # create it first
        allow_any_instance_of(User).to receive(:toggle_watch)
        request.env["HTTP_REFERER"] = scraper_path(scraper)

        post :watch, params: { id: scraper.to_param }

        expect(response).to redirect_to(scraper_path(scraper))
      end
    end
  end

  describe "#watchers" do
    let(:scraper) { create(:scraper, owner: user, name: "watchers_test", full_name: "mlandauer/watchers_test") }

    it "displays watchers page for public scraper" do
      get :watchers, params: { id: scraper.to_param }
      expect(response).to have_http_status(:success)
    end

    context "when signed in" do
      before { sign_in user }

      it "displays watchers page" do
        get :watchers, params: { id: scraper.to_param }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "#history" do
    let(:scraper) { create(:scraper, owner: user, name: "history_test", full_name: "mlandauer/history_test") }

    it "displays history page for public scraper" do
      get :history, params: { id: scraper.to_param }
      expect(response).to have_http_status(:success)
    end

    context "when signed in" do
      before { sign_in user }

      it "displays history page" do
        get :history, params: { id: scraper.to_param }
        expect(response).to have_http_status(:success)
      end
    end
  end

  describe "#running" do
    it "displays running scrapers to anonymous user" do
      allow(Scraper).to receive(:running).and_return([])
      get :running
      expect(response).to have_http_status(:success)
    end

    context "when signed in" do
      before { sign_in user }

      it "displays running scrapers filtered by authorization" do
        scraper1 = create(:scraper, owner: user, name: "running1", full_name: "mlandauer/running1")
        scraper2 = create(:scraper, owner: user, name: "running2", full_name: "mlandauer/running2")
        allow(Scraper).to receive(:running).and_return([scraper1, scraper2])

        get :running

        expect(response).to have_http_status(:success)
        expect(assigns(:scrapers)).to match_array([scraper1, scraper2])
      end

      it "filters out scrapers user cannot see" do
        other_user = create(:user, nickname: "otheruser")
        private_scraper = create(:scraper, owner: other_user, name: "private", full_name: "otheruser/private", private: true)
        allow(Scraper).to receive(:running).and_return([private_scraper])

        get :running

        expect(response).to have_http_status(:success)
        expect(assigns(:scrapers)).to be_empty
      end
    end
  end

  describe "#toggle_privacy" do
    let(:scraper) { create(:scraper, owner: user, name: "privacy_test", full_name: "mlandauer/privacy_test", private: false) }

    context "when not signed in" do
      it "redirects to sign in page" do
        post :toggle_privacy, params: { id: scraper.to_param }
        expect(response).to redirect_to new_user_session_path
      end
    end

    context "when signed in as admin" do
      before do
        user.update!(admin: true)
        sign_in user
      end

      it "toggles privacy from public to private" do
        scraper # create it first
        # rubocop:disable RSpec/VerifiedDoubles
        # Using unverified double for GitHub API client
        github_client = double("Octokit::Client")
        # rubocop:enable RSpec/VerifiedDoubles
        allow_any_instance_of(User).to receive(:github).and_return(github_client)
        allow(github_client).to receive(:update_privacy)

        post :toggle_privacy, params: { id: scraper.to_param }

        scraper.reload
        expect(scraper.private).to be true
        expect(github_client).to have_received(:update_privacy).with("mlandauer/privacy_test", true)
        expect(response).to redirect_to(scraper)
        expect(flash[:notice]).to include("private")
      end

      it "toggles privacy from private to public" do
        scraper.update!(private: true)
        # rubocop:disable RSpec/VerifiedDoubles
        github_client = double("Octokit::Client")
        # rubocop:enable RSpec/VerifiedDoubles
        allow_any_instance_of(User).to receive(:github).and_return(github_client)
        allow(github_client).to receive(:update_privacy)

        post :toggle_privacy, params: { id: scraper.to_param }

        scraper.reload
        expect(scraper.private).to be false
        expect(github_client).to have_received(:update_privacy).with("mlandauer/privacy_test", false)
        expect(response).to redirect_to(scraper)
        expect(flash[:notice]).to include("public")
      end

      it "uses a transaction for privacy update" do
        scraper # create it first
        # rubocop:disable RSpec/VerifiedDoubles
        github_client = double("Octokit::Client")
        # rubocop:enable RSpec/VerifiedDoubles
        allow_any_instance_of(User).to receive(:github).and_return(github_client)
        allow(github_client).to receive(:update_privacy).and_raise("GitHub API error")

        expect do
          post :toggle_privacy, params: { id: scraper.to_param }
        end.to raise_error("GitHub API error")

        scraper.reload
        expect(scraper.private).to be false # Should rollback
      end
    end
  end

  describe "CanCan::AccessDenied handling" do
    before { sign_in user }

    it "raises RecordNotFound instead of AccessDenied" do
      other_user = create(:user, nickname: "otheruser")
      scraper = create(:scraper, owner: other_user, name: "forbidden", full_name: "otheruser/forbidden")

      expect { get :settings, params: { id: scraper.to_param } }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
