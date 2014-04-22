set :stage, :local
set :rails_env, :production
set :branch, :http_proxy

role :app, %w{deploy@localhost}
role :web, %w{deploy@localhost}
role :db,  %w{deploy@localhost}

set :ssh_options, {
  port: 2200
}
