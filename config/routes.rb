Rails.application.routes.draw do
  # Old urls getting redirected to new ones
  get "/api", to: redirect {|params, req| "/documentation/api?#{req.query_string}"}
  # This just gets redirected elsewhere
  get '/settings', to: "owners#settings_redirect"
  # TODO: Hmm would be nice if this could be tidier

  ActiveAdmin.routes(self)
  namespace "admin" do
    resource :site_settings, only: [] do
      post "toggle_read_only_mode"
      post "update_maximum_concurrent_scrapers"
    end
  end

  # Owner.table_exists? is workaround to allow migration to add STI Owner/User table to run
  if Owner.table_exists?
    devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  end

  get "/discourse/sso", to: "discourse_sso#sso"

  # The sync refetch route is being added after this stuff. We need it added before so repeating
  get 'sync/refetch', controller: 'render_sync/refetches', action: 'show'

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
  get 'search', to: "search#search"

  # Redirect old language pages
  get '/documentation/ruby', to: redirect('/documentation')
  get '/documentation/php', to: redirect('/documentation')
  get '/documentation/perl', to: redirect('/documentation')
  get '/documentation/python', to: redirect('/documentation')
  get '/documentation/nodejs', to: redirect('/documentation')

  resources :documentation, only: :index do
    collection do
      get "api"
      get "what_is_new"
      get 'run_locally'
      get 'secret_values'
      get "scraping_javascript_sites"
      get 'libraries'
      get 'language_version'
      get 'webhooks'
    end
  end

  get '/pricing', to: redirect('/supporters/new')

  # Hmm not totally sure about this url.
  post "/run", to: "api#run_remote"

  resources :connection_logs, only: :create

  resources :users, only: :index do
    # This url begins with /users so that we don't stop users have scrapers called watching
    member do
      get 'watching'
    end
    collection do
      get 'stats'
    end
  end
  resources :owners, only: [] do
    member do
      get 'settings'
      post 'settings/reset_key', as: 'reset_key', action: 'reset_key'
      post 'watch'
    end
  end

  # TODO: Don't allow a user to be called "scrapers"
  resources :scrapers, only: [:new, :create, :index] do
    get 'github', on: :new
    collection do
      get 'page/:page', :action => :index
      post 'github', to: "scrapers#create_github"
      get 'github_form'
      get 'running'
    end
  end

  resources :supporters, only: [:new, :create, :update, :index] do
    collection do
      post 'create_one_time'
    end
  end

  # These routes with path: "/" need to be at the end
  resources :owners, path: "/", only: [:show, :update]
  resources :users, path: "/", only: :show
  resources :organizations, path: "/", only: :show

  # Escaping of params with "/" in them changed in Rails 4.1
  #
  # resources :scrapers, path: "/", id: /[^\/]+\/[^\/]+/, only: [:show, :update, :destroy] do
  #   member do
  #     get 'data'
  #     get 'watchers'
  #     get 'settings'
  #
  #     post 'watch'
  #     post 'run'
  #     post 'stop'
  #     post 'clear'
  #   end
  # end
  get '*id/data', to: "api#data", as: :data_scraper, id: /[^\/]+\/[^\/]+/
  get '*id/watchers', to: "scrapers#watchers", as: :watchers_scraper, id: /[^\/]+\/[^\/]+/
  get '*id/settings', to: "scrapers#settings", as: :settings_scraper, id: /[^\/]+\/[^\/]+/
  get '*id/history', to: "scrapers#history", as: :history_scraper, id: /[^\/]+\/[^\/]+/
  post '*id/watch', to: "scrapers#watch", as: :watch_scraper, id: /[^\/]+\/[^\/]+/
  post '*id/run', to: "scrapers#run", as: :run_scraper, id: /[^\/]+\/[^\/]+/
  post '*id/stop', to: "scrapers#stop", as: :stop_scraper, id: /[^\/]+\/[^\/]+/
  post '*id/clear', to: "scrapers#clear", as: :clear_scraper, id: /[^\/]+\/[^\/]+/
  get '*id', to: "scrapers#show", as: :scraper, id: /[^\/]+\/[^\/]+/
  put '*id', to: "scrapers#update", id: /[^\/]+\/[^\/]+/
  patch '*id', to: "scrapers#update", id: /[^\/]+\/[^\/]+/
  delete '*id', to: "scrapers#destroy", id: /[^\/]+\/[^\/]+/
end
