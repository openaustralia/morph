# typed: false
# frozen_string_literal: true

set :stage, :local
set :rails_env, :production

before :deploy, :deploy_from_local_repo

task :deploy_from_local_repo do
  set :repo_url, "file:///tmp/.git"
  set :branch, (proc { `git rev-parse --abbrev-ref HEAD`.chomp })
  run_locally do
    execute "tar -zcvf /tmp/repo.tgz .git"
  end
  on roles(:all) do
    upload! "/tmp/repo.tgz", "/tmp/repo.tgz"
    execute "tar -zxvf /tmp/repo.tgz -C /tmp"
  end
end

role :app, %w[deploy@localhost]
role :web, %w[deploy@localhost]
role :db,  %w[deploy@localhost]

set :ssh_options, port: 2200
