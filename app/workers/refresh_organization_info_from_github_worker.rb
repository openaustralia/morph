# typed: strict
# frozen_string_literal: true

class RefreshOrganizationInfoFromGithubWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(id: Integer).void }
  def perform(id)
    org = Organization.find(id)
    # Use first member of organization to make the github calls
    first_user = org.users.first
    org.refresh_info_from_github!(first_user) if first_user
  end
end
