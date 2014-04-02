Morph::Application.routes.draw do
  ActiveAdmin.routes(self)
  # Owner.table_exists? is workaround to allow migration to add STI Owner/User table to run
  if Owner.table_exists?
    devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  end

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
  end
  get "/pricing", to: "documentation#pricing"
  # Hmm not totally sure about this url.
  post "/run", to: "api#run_remote"
  get "/test", to: "api#test"
  get '/settings', to: "users#settings", as: :user_settings
  post '/settings/reset_key', to: "users#reset_key", as: :user_reset_key

  # TODO: Don't allow a user to be called "scrapers"
  resources :scrapers, path: '/scrapers', only: [:new, :create, :index] do
    get 'page/:page', :action => :index, :on => :collection
    get 'github', on: :new
    post 'github', to: "scrapers#create_github", on: :collection
    get 'github_form', on: :collection
    get 'scraperwiki', on: :new
    post 'scraperwiki', to: "scrapers#create_scraperwiki", on: :collection
  end
  # This url begins with /users so that we don't stop users have scrapers called watching
  get '/users/:id/watching', to: "users#watching", as: :user_watching
  get '/users', to: "users#index"
  resources :owners, path: "/", only: :show
  post '/:id/watch', to: "owners#watch", as: :owner_watch
  resources :users, path: "/", only: :show
  resources :organizations, path: "/", only: :show
  # TODO: Hmm would be nice if this could be tidier
  get '/scraperwiki_forks/new', to: redirect {|params, req|
    if req.query_string.empty?
      "/scrapers/new/scraperwiki"
    else
      "/scrapers/new/scraperwiki?#{req.query_string}"
    end
  }

  #resources "scraperwiki_forks", only: [:new, :create]

  get '/*id/data', to: "scrapers#data", as: :scraper_data
  post '/*id/watch', to: "scrapers#watch", as: :scraper_watch
  get '/*id/watchers', to: "scrapers#watchers", as: :scraper_watchers
  get '/*id/settings', to: "scrapers#settings", as: :scraper_settings
  get "/*id", to: "scrapers#show", as: :scraper
  delete "/*id", to: "scrapers#destroy"
  patch "/*id", to: "scrapers#update"
  post "/*id/run", to: "scrapers#run", as: :run_scraper
  post "/*id/clear", to: "scrapers#clear", as: :clear_scraper
  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
