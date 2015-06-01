class RunWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(run_id)
    run = Run.find(run_id)
    Morph::Runner.new(run).synch_and_go!
  end
end
