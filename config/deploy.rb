set :application, 'morph'
set :repo_url, 'https://github.com/openaustralia/morph.git'

set :rvm_ruby_version, '2.7.6'

set :branch, -> {
  branch = ENV['BRANCH'] || `git rev-parse --abbrev-ref HEAD`.strip

  # Check for uncommitted changes
  unless `git status --porcelain`.strip.empty?
    puts "\n⚠️  WARNING: You have uncommitted changes locally"
  end

  # Check if branch exists in deployment repo
  local_sha = `git rev-parse #{branch}`.strip
  remote_sha = `git ls-remote #{fetch(:repo_url)} #{branch} 2>/dev/null`.split.first

  if remote_sha.nil? || remote_sha.strip.empty?
    puts "⚠️  WARNING: Branch '#{branch}' doesn't exist in #{fetch(:repo_url)}"
  elsif local_sha != remote_sha
    puts "⚠️  WARNING: Branch '#{branch}' (commit #{local_sha[0, 9]}) differs from #{fetch(:repo_url)} (commit #{remote_sha[0,9]})"
  end

  if fetch(:repo_url) != 'https://github.com/openaustralia/morph.git'
    puts "⚠️  WARNING: Deploying branch #{branch} from a fork of the openaustralia repo: #{fetch(:repo_url)}"
  else
    puts "⚠️  NOTE: deploying branch #{branch} rather than main" if branch != "main"
  end

  branch
}

set :deploy_to, '/var/www'
# set :scm, :git

# set :format, :pretty
# set :log_level, :debug
# set :pty, true

set :linked_files, %w{config/database.yml config/sync.yml config/morph-github-app.private-key.pem .env}
set :linked_dirs, %w{db/scrapers public/sitemaps tmp/pids log}
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
        execute :rake, "app:update_docker_images RAILS_ENV=production"
      end
    end
  end

  desc "Fix queue run inconsistencies"
  task :fix_queue_run_inconsistencies do
    on roles(:app) do
      within release_path do
        # Wait one minute so that everything has plenty of time to get started before we run this check (and workaround)
        execute :sleep, "60"
        execute :rake, "app:emergency:fix_queue_run_inconsistencies RAILS_ENV=production"
      end
    end
  end
end

namespace :foreman do
  desc "Start the application services"
  task :start do
    on roles(:app) do
      sudo "systemctl start morph.target"
    end
  end

  desc "Stop the application services"
  task :stop do
    on roles(:app) do
      sudo "systemctl stop morph.target"
    end
  end

  desc "Restart the application services"
  task :restart do
    on roles(:app) do
      sudo "systemctl restart morph.target"
    end
  end
end

namespace :searchkick do
  namespace :reindex do
    desc "Reindex all models"
    task :all do
      on roles(:app) do
        within release_path do
          execute :rake, "searchkick:reindex:all RAILS_ENV=production"
        end
      end
    end
  end
end

# TODO: Hmmm... Need to think about the best order for doing these
after 'deploy:publishing', 'deploy:restart'
before "deploy:restart", "deploy:docker"
after "deploy:docker", "foreman:restart"
# Disable the searchkick reindex on deploys because it just takes *way* too long
# However, not that on a first deploy you do need to run the searchkick:reindex:all
# task otherwise things won't work as expected
#after "foreman:restart", "searchkick:reindex:all"

# This is a horrrible workaround for sidekiq losing running jobs on the queue when it is restarted
# For the longest time we've been running this by hand after every deploy, hoping somewhat foolishly
# that not-automating the workaround would compell us to fix the problem properly. Well this clearly
# hasn't happened. So, it's time to automate the workaround
# TODO: Remove this workaround as soon as we can
after "deploy:cleanup", "deploy:fix_queue_run_inconsistencies"