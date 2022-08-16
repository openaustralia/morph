# typed: strict
# frozen_string_literal: true

class SynchroniseRepoWorker
  extend T::Sig

  include Sidekiq::Worker
  sidekiq_options backtrace: true

  sig { params(id: Integer).void }
  def perform(id)
    Scraper.find(id).synchronise_repo
  end
end
