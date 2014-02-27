class RunWorker
  include Sidekiq::Worker

  def perform(run_id)
    Run.find(run_id).synch_and_go!
  end
end