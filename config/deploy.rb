set :application, 'morph'
set :repo_url, 'https://github.com/openaustralia/morph.git'

set :rvm_ruby_version, '2.0.0-p353' 

# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }

# set :deploy_to, '/var/www/my_app'
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/database.yml .env}
set :linked_dirs, %w{db/scrapers}
# set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# set :default_env, { path: "/opt/ruby/bin:$PATH" }
# set :keep_releases, 5

namespace :deploy do

  desc 'Restart application'
  task :restart do
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  after :restart, :clear_cache do
    on roles(:web), in: :groups, limit: 3, wait: 10 do
      # Here we can do anything such as:
      # within release_path do
      #   execute :rake, 'cache:clear'
      # end
    end
  end

  after :finishing, 'deploy:cleanup'

  desc "Build docker images"
  task :docker do
    on roles(:app) do
      within release_path do
        execute :bundle, "exec rake app:update_docker_image RAILS_ENV=production"
      end
    end
  end
end

before "deploy:restart", "deploy:docker"
after "deploy:docker", "foreman:restart"

namespace :foreman do
  desc "Start the application services"
  task :start do
    on roles(:app) do
      sudo "service morph start"
    end
  end

  desc "Stop the application services"
  task :stop do
    on roles(:app) do
      sudo "service morph stop"
    end
  end

  desc "Restart the application services"
  task :restart do
    on roles(:app) do
      sudo "service morph restart"
    end
  end
end
