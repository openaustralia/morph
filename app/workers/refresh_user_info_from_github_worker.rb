# typed: false
# frozen_string_literal: true

class RefreshUserInfoFromGithubWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(id)
    User.find(id).refresh_info_from_github!
  end
end
