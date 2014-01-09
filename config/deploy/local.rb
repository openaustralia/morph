set :stage, :local
set :rails_env, :production

role :app, %w{deploy@localhost}
role :web, %w{deploy@localhost}
role :db,  %w{deploy@localhost}

set :ssh_options, {
  port: 2200
}