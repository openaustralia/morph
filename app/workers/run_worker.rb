class RunWorker
  include Sidekiq::Worker
  # TODO: Make backtrace: true to be a default option for all workers
  sidekiq_options queue: :scraper, backtrace: true, unique: true

  def perform(run_id)
    run = Run.find(run_id)
    Morph::Runner.new(run).synch_and_go!
  end
end
