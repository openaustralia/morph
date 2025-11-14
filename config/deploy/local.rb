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

# Use 192.168.56.2 instead of localhost so you can set the identity file in ~/.ssh/config just like morph.io
role :app, %w[deploy@192.168.56.2]
role :web, %w[deploy@192.168.56.2]
role :db,  %w[deploy@192.168.56.2]

set :ssh_options, port: 22
