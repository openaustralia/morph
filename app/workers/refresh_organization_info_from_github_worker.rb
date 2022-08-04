# typed: false
# frozen_string_literal: true

class RefreshOrganizationInfoFromGithubWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(id)
    org = Organization.find(id)
    # Use first member of organization to make the github calls
    first_user = org.users.first
    org.refresh_info_from_github!(first_user.octokit_client) if first_user
  end
end
