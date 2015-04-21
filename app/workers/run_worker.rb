class RunWorker
  include Sidekiq::Worker
  sidekiq_options backtrace: true

  def perform(run_id)
    Run.find(run_id).synch_and_go!
  end
end
