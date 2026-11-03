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

    runner = Morph::Runner.new(run)
    # The container count is the only enforcement of the concurrency cap. When
    # there's no free slot, try again later rather than raising, so the retry
    # and dead sets don't fill. Two workers can race past this check by a slot
    # or so and that is accepted.
    if Morph::Runner.available_slots <= 0 && runner.container_for_run.nil?
      self.class.perform_in(RETRY_DELAY, run_id)
      return
    end

    runner.synch_and_go_with_logging!
  end
end
