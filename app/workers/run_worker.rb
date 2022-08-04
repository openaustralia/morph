# typed: true
# frozen_string_literal: true

class RunWorker
  class NoRemainingSlotsError < StandardError
  end

  include Sidekiq::Worker
  # TODO: Make backtrace: true to be a default option for all workers
  sidekiq_options queue: :scraper, backtrace: true

  def perform(run_id)
    run = Run.find_by(id: run_id)
    # If the run has been deleted (the scraper has been deleted) then just
    # skip over this and don't do anything
    return if run.nil?

    runner = Morph::Runner.new(run)
    raise NoRemainingSlotsError if Morph::Runner.available_slots.zero? && runner.container_for_run.nil?

    runner.synch_and_go!
  end
end
