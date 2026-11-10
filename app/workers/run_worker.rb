# typed: strict
# frozen_string_literal: true

class RunWorker
  extend T::Sig

  # How long to wait before trying again when every slot is taken
  RETRY_DELAY = T.let(30, Integer)

  include Sidekiq::Worker
  # TODO: Make backtrace: true to be a default option for all workers
  sidekiq_options queue: :scraper, backtrace: true

  sig { params(run_id: Integer).void }
  def perform(run_id)
    run = Run.find_by(id: run_id)
    # If the run has been deleted (the scraper has been deleted) then just
    # skip over this and don't do anything
    return if run.nil?
    # A run that was stopped while waiting for a slot still has its scheduled
    # job. Nothing will run it, so don't keep polling Docker and Redis for it.
    return if run.finished?

    runner = Morph::Runner.new(run)
    # The container count is the only enforcement of the concurrency cap, and
    # SlotClaims covers the gap before a run's container exists. When there's no
    # free slot, try again later rather than raising, so the retry and dead
    # sets don't fill.
    unless Morph::SlotClaims.claim(run_id, has_container: !runner.container_for_run.nil?)
      self.class.perform_in(RETRY_DELAY, run_id)
      return
    end

    begin
      runner.synch_and_go_with_logging!
    ensure
      Morph::SlotClaims.release(run_id)
    end
  end
end
