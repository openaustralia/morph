# typed: false
# frozen_string_literal: true

class UpdateDomainWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  # Look up meta info for a domain
  def perform(id)
    Domain.find(id).update_meta!
  end
end
