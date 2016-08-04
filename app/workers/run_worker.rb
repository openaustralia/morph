class RunWorker
  include Sidekiq::Worker
  # TODO: Make backtrace: true to be a default option for all workers
  sidekiq_options queue: :scraper, backtrace: true, unique: true

  def perform(run_id)
    run = Run.find_by(id: run_id)
    # If the run has been deleted (the scraper has been deleted) then just
    # skip over this and don't do anything
    Morph::Runner.new(run).synch_and_go! if run
  end
end
