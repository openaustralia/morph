# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "tasks" do # rubocop:disable RSpec/DescribeClass
  describe "db:factory:load", type: :integration do
    before do
      Rails.application.load_tasks if Rake::Task.tasks.empty?
    end

    let(:task) { "db:factory:load" }

    context "when not in development environment" do
      before do
        allow(Rails.env).to receive(:development?).and_return(false)
      end

      it "raises an error" do
        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to raise_error("This task can only be run in development environment!")
      end
    end

    context "when in development environment" do
      before do
        allow(Rails.env).to receive(:development?).and_return(true)
        allow(Rake::Task["db:reset"]).to receive(:invoke)
        allow(Rake::Task["db:stats"]).to receive(:invoke)
        allow(Searchkick).to receive(:disable_callbacks)
        allow(Scraper).to receive(:skip_github_validations=)
        allow(FactoryBot).to receive(:lint)
        allow(SiteSetting).to receive(:maximum_concurrent_scrapers)
        # User might be used in the task
        create(:user, admin: true)
      end

      it "invokes db:reset and db:stats" do
        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(/Resetting database.../).to_stdout
        expect(Rake::Task["db:reset"]).to have_received(:invoke)
        expect(Rake::Task["db:stats"]).to have_received(:invoke)
      end

      it "disables Searchkick and GitHub validations" do
        Rake::Task[task].reenable
        Rake::Task[task].invoke
        expect(Searchkick).to have_received(:disable_callbacks)
        expect(Scraper).to have_received(:skip_github_validations=).with(true)
      end

      it "runs FactoryBot linting" do
        Rake::Task[task].reenable
        Rake::Task[task].invoke
        expect(FactoryBot).to have_received(:lint).with(traits: true)
      end

      it "triggers creation of SiteSetting" do
        Rake::Task[task].reenable
        Rake::Task[task].invoke
        expect(SiteSetting).to have_received(:maximum_concurrent_scrapers)
      end

      it "outputs admin user info" do
        admin = User.find_by admin: true
        Rake::Task[task].reenable
        expect { Rake::Task[task].invoke }.to output(/Admin user nickname: #{admin.nickname}/).to_stdout
      end
    end
  end
end
