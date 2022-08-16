# typed: strict
# frozen_string_literal: true

class RefreshUserOrganizationsWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(id: Integer).void }
  def perform(id)
    User.find(id).refresh_organizations!
  end
end
