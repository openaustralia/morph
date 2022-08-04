# typed: false
# frozen_string_literal: true

class RefreshUserOrganizationsWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(id)
    User.find(id).refresh_organizations!
  end
end
