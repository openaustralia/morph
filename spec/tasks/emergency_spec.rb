# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "tasks" do # rubocop:disable RSpec/DescribeClass
  describe "emergency", type: :integration do
    before do
      Rails.application.load_tasks if Rake::Task.tasks.empty?
    end

    #       desc "Show queue / run inconsistencies - does not make any changes"
    describe "app:emergency:show_queue_run_inconsistencies" do
      let(:task) { "app:emergency:show_queue_run_inconsistencies" }

      it "shows queue and run inconsistencies" do
        allow(Morph::Emergency).to receive(:find_all_runs_on_the_queue).and_return([1, 2])
        allow(Morph::Emergency).to receive(:find_all_runs_associated_with_current_containers).and_return([2, 3])
        allow(Morph::Emergency).to receive(:find_all_unfinished_runs_attached_to_scrapers).and_return([3, 4])

        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(/The following runs do not have jobs on the queue:\s+\[3\]\s+Unfinished runs attached to scrapers that do not have jobs on the queue:\s+\[3, 4\]/).to_stdout
      end
    end

    #       desc "Fix queue inconsistencies - ONLY RUN THIS AFTER show_queue_run_inconsistencies"
    describe "app:emergency:fix_queue_run_inconsistencies" do
      let(:task) { "app:emergency:fix_queue_run_inconsistencies" }

      it "fixes queue inconsistencies by re-queuing runs" do
        allow(Morph::Emergency).to receive(:find_all_runs_on_the_queue).and_return([1, 2])
        allow(Morph::Emergency).to receive(:find_all_unfinished_runs_attached_to_scrapers).and_return([2, 3])
        allow(RunWorker).to receive(:perform_async)

        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(/Putting the following runs back on the queue:\s+\[3\]/).to_stdout
        expect(RunWorker).to have_received(:perform_async).with(3)
      end
    end

    #       desc "Get meta info for all domains in the connection logs"
    describe "app:emergency:get_all_meta_info_for_connection_logs" do
      let(:task) { "app:emergency:get_all_meta_info_for_connection_logs" }

      it "gets meta info for domains in connection logs" do
        group = instance_double(ActiveRecord::Relation)
        allow(ConnectionLog).to receive(:group).with(:host).and_return(group)
        allow(group).to receive(:pluck).with(:host).and_return(%w[example.com already_exists.com])
        allow(Domain).to receive(:exists?).with(name: "example.com").and_return(false)
        allow(Domain).to receive(:exists?).with(name: "already_exists.com").and_return(true)
        allow(Domain).to receive(:create!).with(name: "example.com").and_return(instance_double(Domain, id: 123))
        allow(UpdateDomainWorker).to receive(:perform_async)

        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(%r{Queueing 1/2 example.com\s+Skipping 2/2 already_exists.com}).to_stdout
        expect(UpdateDomainWorker).to have_received(:perform_async).with(123)
      end
    end

    #       desc "Delete duplicate enqueued Sidekiq scraper jobs. Sidekiq should be stopped for this to be effective"
    describe "app:emergency:delete_duplicate_scraper_jobs" do
      let(:task) { "app:emergency:delete_duplicate_scraper_jobs" }

      it "deletes duplicate scraper jobs" do
        job1 = instance_double(Sidekiq::Job, item: { "args" => [1] })
        job2 = instance_double(Sidekiq::Job, item: { "args" => [1] })
        job3 = instance_double(Sidekiq::Job, item: { "args" => [2] })
        queue = [job1, job2, job3]

        allow(Sidekiq::Queue).to receive(:[]).with("scraper").and_return(queue)
        allow(job1).to receive(:delete)
        allow(job2).to receive(:delete)
        allow(job3).to receive(:delete)

        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(/Deleting duplicate job for run ID: 1\.\.\.\s+Deleting duplicate job for run ID: 1\.\.\./).to_stdout
        expect(job1).to have_received(:delete)
        expect(job2).to have_received(:delete)
        expect(job3).not_to have_received(:delete)
      end
    end

    #       desc "Clears a backlogged queue by queuing retries in a loop"
    describe "app:emergency:work_off_run_queue_retries" do
      let(:task) { "app:emergency:work_off_run_queue_retries" }

      it "works off run queue retries", slow: true do
        retry1 = instance_double(Sidekiq::SortedEntry, klass: "RunWorker")
        retry2 = instance_double(Sidekiq::SortedEntry, klass: "RunWorker")

        allow(Morph::Runner).to receive(:available_slots).and_return(5)
        # number_of_slots_to_keep_free = 4, so 1 slot available
        allow(retry1).to receive(:retry)
        allow(retry2).to receive(:retry)
        allow(Kernel).to receive(:sleep)

        # We need to make the loop terminate.
        # The task uses while (run_retries = Sidekiq::RetrySet.new.select { |j| j.klass == "RunWorker" })
        # and then breaks if run_retries.count.zero?

        call_count = 0
        allow(Sidekiq::RetrySet).to receive(:new) do
          call_count += 1
          if call_count == 1
            [retry1, retry2]
          else
            []
          end
        end

        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(/2 in the retry queue\. Checking for free slots\.\.\.\s+1 retry slots available\. Queuing jobs\.\.\.\s+Waiting 30 seconds before checking again\.\s+No runs in the retry queue\.\s+Retry queue cleared\. Exiting\./).to_stdout
        expect(retry1).to have_received(:retry)
        expect(retry2).not_to have_received(:retry)
      end
    end
  end
end
