Morph::Application.routes.draw do
  # Old urls getting redirected to new ones
  get "/api", to: redirect {|params, req| "/documentation/api?#{req.query_string}"}
  # This just gets redirected elsewhere
  get '/settings', to: "owners#settings"
  # TODO: Hmm would be nice if this could be tidier
  get '/scraperwiki_forks/new', to: redirect {|params, req|
    if req.query_string.empty?
      "/scrapers/new/scraperwiki"
    else
      "/scrapers/new/scraperwiki?#{req.query_string}"
    end
  }

  ActiveAdmin.routes(self)
  # Owner.table_exists? is workaround to allow migration to add STI Owner/User table to run
  if Owner.table_exists?
    devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  end

  get "/discourse/sso", to: "discourse_sso#sso"

  # The sync refetch route is being added after this stuff. We need it added before so repeating
  get 'sync/refetch', controller: 'sync/refetches', action: 'show'

  devise_scope :user do
    get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
  end

  # TODO: Put this in a path where it won't conflict
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/admin/jobs'
  end

  root 'static#index'
  resources :documentation, only: :index do
    collection do
      get "api"
      get "what_is_new"
      get "examples/australian_members_of_parliament"
    end
  end
  get "/pricing", to: "documentation#pricing"

  # Hmm not totally sure about this url.
  post "/run", to: "api#run_remote"
  get "/test", to: "api#test"

  resources :connection_logs, only: :create

  resources :users, only: :index do
    # This url begins with /users so that we don't stop users have scrapers called watching
    get 'watching'
  end
  resources :owners, only: [] do
    get 'settings'
    post 'reset_key', path: 'settings/reset_key'
    post 'watch'
  end

  # TODO: Don't allow a user to be called "scrapers"
  resources :scrapers, only: [:new, :create, :index] do
    get 'page/:page', :action => :index, :on => :collection
    get 'github', on: :new
    post 'github', to: "scrapers#create_github", on: :collection
    get 'github_form', on: :collection
    get 'scraperwiki', on: :new
    post 'scraperwiki', to: "scrapers#create_scraperwiki", on: :collection
  end

  # These routes with path: "/" need to be at the end
  resources :owners, path: "/", only: :show
  resources :users, path: "/", only: [:show, :update]
  resources :organizations, path: "/", only: :show
  resources :scrapers, path: "/", id: /[^\/]+\/[^\/]+/, only: [:show, :update, :destroy] do
    get 'data'
    get 'watchers'
    get 'settings'

    post 'watch'
    post 'run'
    post 'stop'
    post 'clear'
  end
end
