# typed: strict
# frozen_string_literal: true

class UpdateDomainWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  # Look up meta info for a domain
  sig { params(id: Integer).void }
  def perform(id)
    Domain.find(id).update_meta!
  end
end
