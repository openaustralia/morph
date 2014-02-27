class RunWorker
  include Sidekiq::Worker

  def perform(run_id)
    Sync::Model.enable do
      Run.find(run_id).synch_and_go!
    end
  end
end