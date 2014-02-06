Morph::Application.routes.draw do
  # Owner.table_exists? is workaround to allow migration to add STI Owner/User table to run
  if Owner.table_exists?
    devise_for :users, :controllers => { :omniauth_callbacks => "users/omniauth_callbacks" }
  end

  devise_scope :user do
    get 'sign_out', :to => 'devise/sessions#destroy', :as => :destroy_user_session
    get 'sign_in', :to => 'devise/sessions#new', :as => :new_user_session
  end
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  root 'static#index'
  get "/api", to: "static#api"
  get "/documentation", to: 'static#documentation'
  # Hmm not totally sure about this url.
  post "/run", to: "api#run_remote"
  get "/test", to: "api#test"
  get '/settings', to: "users#settings", as: :user_settings
  post '/settings/reset_key', to: "users#reset_key", as: :user_reset_key

  # TODO: Don't allow a user to be called "new". Chances are GitHub enforces this anyway.
  resources :scrapers, path: '/', only: [:new, :create]
  resources :owners, path: "/", only: :show
  resources :users, path: "/", only: :show
  resources :organizations, path: "/", only: :show
  # TODO Not very happy with this URL but this will do for the time being
  resources "scraperwiki_forks", only: [:new, :create]

  get '/*id/data', to: "scrapers#data", as: :scraper_data
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
