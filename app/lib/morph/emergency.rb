# typed: strict
# frozen_string_literal: true

module Morph
  module Emergency
    extend T::Sig

    RUN_WORKER_CLASS_NAME = "RunWorker"
    SCRAPER_QUEUE = "scraper"

    # Returns the ids for all the runs currently on the queue (including retries)
    sig { returns(T::Array[Integer]) }
    def self.find_all_runs_on_the_queue
      queue = []
      # Runs on the retry queue
      Sidekiq::RetrySet.new.each do |job|
        queue << job.args.first if job.klass == RUN_WORKER_CLASS_NAME
      end
      # Runs on the queue
      Sidekiq::Queue.new(SCRAPER_QUEUE).each do |job|
        queue << job.args.first if job.klass == RUN_WORKER_CLASS_NAME
      end
      # Runs currently being processed on the queue
      Sidekiq::Workers.new.each do |_process_id, _thread_id, work|
        queue << work["payload"]["args"].first if work["payload"]["class"] == RUN_WORKER_CLASS_NAME
      end
      # Remove duplicates just in case a job has moved from one queue to another
      # while we've been doing this
      queue.uniq.sort
    end

    # Returns an array of run ids
    sig { returns(T::Array[Integer]) }
    def self.find_all_runs_associated_with_current_containers
      # Find all containers that are associated with runs
      containers = Docker::Container.all(all: true).map do |container|
        run = Morph::Runner.run_for_container(container)
        run&.id
      end
      containers.compact.sort
    end

    # Returns an array of run ids
    sig { returns(T::Array[Integer]) }
    def self.find_all_unfinished_runs_attached_to_scrapers
      Run.where(finished_at: nil).where.not(scraper_id: nil).ids
    end
  end
end
