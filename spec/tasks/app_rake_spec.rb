# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "rake app", type: :integration do # rubocop:disable RSpec/DescribeClass
  before do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
  end

  # desc "Stop long-running scraper containers (should be run from cron job)"
  describe "#stop_long_running_scrapers" do
    it "stops long running scrapers" do
      container = double("Container", json: { "State" => { "StartedAt" => 2.days.ago.iso8601 } })
      expect(Morph::DockerUtils).to receive(:running_containers).and_return([container])
      expect(Morph::Runner).to receive(:run_id_for_container).with(container).and_return(1)
      run = instance_double(Run, full_name: "test/scraper")
      expect(Morph::Runner).to receive(:run_for_container).with(container).and_return(run)
      runner = instance_double(Morph::Runner)
      expect(Morph::Runner).to receive(:new).with(run).and_return(runner)
      expect(runner).to receive(:log).with(nil, :internalerr, /Stopping scraper because it has run longer than/)
      expect(container).to receive(:kill)

      task = "app:stop_long_running_scrapers"
      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Stopping test\/scraper because its container has been running longer than/).to_stdout
    end

    it "does not stop recently started scrapers" do
      container = double("Container", json: { "State" => { "StartedAt" => 1.hour.ago.iso8601 } })
      expect(Morph::DockerUtils).to receive(:running_containers).and_return([container])
      expect(Morph::Runner).to receive(:run_id_for_container).with(container).and_return(1)
      expect(container).not_to receive(:kill)

      task = "app:stop_long_running_scrapers"
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end

  # desc "Run scrapers that need to run once per day (this task should be called from a cron job)
  describe "#auto_run_scrapers" do
    it "queues scrapers with auto_run enabled" do
      scraper = create(:scraper, auto_run: true)
      create(:scraper, auto_run: false)

      task = "app:auto_run_scrapers"
      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Queued 1 scrapers to run over the next 24 hours/).to_stdout
      expect(ScraperAutoRunWorker.jobs.size).to eq(1)
      expect(ScraperAutoRunWorker.jobs.first["args"]).to eq([scraper.id])
    end
  end

  # desc "Send out alerts for all users (Run once per day with a cron job)"
  describe "#send_alerts" do
    it "calls User.process_alerts" do
      expect(User).to receive(:process_alerts)
      task = "app:send_alerts"
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end

  # desc "Refresh info for all users from github"
  describe "#refresh_all_users" do
    it "queues refresh jobs for all users" do
      user = create(:user)
      task = "app:refresh_all_users"
      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Put jobs on to the background queue to refresh all user info from github/).to_stdout
      expect(RefreshUserInfoFromGithubWorker.jobs.size).to eq(1)
      expect(RefreshUserInfoFromGithubWorker.jobs.first["args"]).to eq([user.id])
    end
  end

  # desc "Refresh info for all organizations from github"
  describe "#refresh_all_organizations" do
    it "queues refresh jobs for all organizations" do
      org = create(:organization)
      task = "app:refresh_all_organizations"
      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Put jobs on to the background queue to refresh all organization info from github/).to_stdout
      expect(RefreshOrganizationInfoFromGithubWorker.jobs.size).to eq(1)
      expect(RefreshOrganizationInfoFromGithubWorker.jobs.first["args"]).to eq([org.id])
    end
  end

  # desc "Downloads latest docker images"
  describe "#update_docker_images" do
    it "calls Morph::DockerRunner.update_docker_images!" do
      expect(Morph::DockerRunner).to receive(:update_docker_images!)
      task = "app:update_docker_images"
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end

  # desc "Promote user to admin"
  describe "#promote_to_admin" do
    it "promotes user to admin" do
      user = create(:user, admin: false)
      allow($stdin).to receive(:gets).and_return(user.nickname)

      task = "app:promote_to_admin"
      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to output(/Which github nickname do you want to promote to admin\?/).to_stdout

      expect(user.reload.admin).to be true
    end

    it "exits if user not found" do
      allow($stdin).to receive(:gets).and_return("nonexistent")

      task = "app:promote_to_admin"
      Rake::Task[task].reenable
      expect { Rake::Task[task].invoke }.to raise_error(SystemExit).and output(/Couldn't find user with nickname 'nonexistent'/).to_stdout
    end
  end

  # desc "Backup databases to db/backups"
  describe "#backup" do
    it "calls Morph::Backup.backup" do
      expect(Morph::Backup).to receive(:backup)
      task = "app:backup"
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end

  # desc "Tidies up Docker containers and images (should be run from a cronjob)"
  describe "#docker_tidy_up" do
    it "invokes docker tidy up tasks" do
      expect(Rake::Task["app:docker:remove_old_unused_images"]).to receive(:invoke)
      expect(Rake::Task["app:docker:delete_dead_containers"]).to receive(:invoke)
      task = "app:docker_tidy_up"
      Rake::Task[task].reenable
      Rake::Task[task].invoke
    end
  end
end
