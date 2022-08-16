# typed: strict
# frozen_string_literal: true

class RefreshUserInfoFromGithubWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(id: Integer).void }
  def perform(id)
    User.find(id).refresh_info_from_github!
  end
end
