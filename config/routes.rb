Morph::Application.routes.draw do
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
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # TODO: Put this in a path where it won't conflict
  require 'sidekiq/web'
  authenticate :user, lambda { |u| u.admin? } do
    mount Sidekiq::Web => '/admin/jobs'
  end

  root 'static#index'
  get "/api", to: redirect {|params, req| "/documentation/api?#{req.query_string}"}
  resources :documentation, only: :index do
    get "api", on: :collection
    get "what_is_new", on: :collection
    get "examples/australian_members_of_parliament", on: :collection
  end
  get "/pricing", to: "documentation#pricing"
  # Hmm not totally sure about this url.
  post "/run", to: "api#run_remote"
  get "/test", to: "api#test"
  # This just gets redirected elsewhere
  get '/settings', to: "owners#settings"

  # TODO: Don't allow a user to be called "scrapers"
  resources :scrapers, only: [:new, :create, :index] do
    get 'page/:page', :action => :index, :on => :collection
    get 'github', on: :new
    post 'github', to: "scrapers#create_github", on: :collection
    get 'github_form', on: :collection
    get 'scraperwiki', on: :new
    post 'scraperwiki', to: "scrapers#create_scraperwiki", on: :collection
  end

  resources :users, only: :index do
    # This url begins with /users so that we don't stop users have scrapers called watching
    get 'watching'
  end
  resources :owners, only: [] do
    get 'settings'
    post 'reset_key', path: 'settings/reset_key'
    post 'watch'
  end

  resources :owners, path: "/", only: :show
  resources :users, path: "/", only: [:show, :update]
  resources :organizations, path: "/", only: :show

  # TODO: Hmm would be nice if this could be tidier
  get '/scraperwiki_forks/new', to: redirect {|params, req|
    if req.query_string.empty?
      "/scrapers/new/scraperwiki"
    else
      "/scrapers/new/scraperwiki?#{req.query_string}"
    end
  }

  resources :connection_logs, only: :create

  get '/*id/data', to: "scrapers#data", as: :scraper_data
  post '/*id/watch', to: "scrapers#watch", as: :scraper_watch
  get '/*id/watchers', to: "scrapers#watchers", as: :scraper_watchers
  get '/*id/settings', to: "scrapers#settings", as: :scraper_settings
  get "/*id", to: "scrapers#show", as: :scraper
  delete "/*id", to: "scrapers#destroy"
  patch "/*id", to: "scrapers#update"
  post "/*id/run", to: "scrapers#run", as: :run_scraper
  post "/*id/stop", to: "scrapers#stop", as: :stop_scraper
  post "/*id/clear", to: "scrapers#clear", as: :clear_scraper
end
