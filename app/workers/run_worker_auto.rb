# Use this when running scrapers automatically. This is so that
# they go on a lower priority queue
class RunWorkerAuto < RunWorker
  sidekiq_options queue: :low
end
