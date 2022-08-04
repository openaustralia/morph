# typed: true
# frozen_string_literal: true

class SynchroniseRepoWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(id)
    Scraper.find(id).synchronise_repo
  end
end
