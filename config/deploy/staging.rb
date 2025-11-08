# typed: false
# frozen_string_literal: true

set :stage, :staging

# Use the url for the origin remote (typically the developer's fork) for staging deployments
# This overrides the default repo_url from deploy.rb
set :repo_url, `git config --get remote.origin.url`.strip

set :deploy_to, -> do
  deploy_server = ENV.fetch('STAGING_DEPLOY_TO') do
    ENV.fetch('STAGING_HOSTNAME') do
      fail "STAGING_HOSTNAME or STAGING_DEPLOY_TO must be set when deploying to staging!" \
             "Use your.own.domain for STAGING_HOSTNAME or ip-address for STAGING_DEPLOY_TO"
    end
  end
  "deploy@#{deploy_server}"
end

role :app, [deploy_to]
role :web, [deploy_to]
role :db, [deploy_to]
