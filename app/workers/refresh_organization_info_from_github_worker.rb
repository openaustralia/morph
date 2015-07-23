class RefreshOrganizationInfoFromGithubWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(id)
    org = Organization.find(id)
    # Use first member of organization to make the github calls
    org.refresh_info_from_github!(org.users.first.octokit_client)
  end
end
