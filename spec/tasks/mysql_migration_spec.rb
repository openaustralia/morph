# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe "tasks" do # rubocop:disable RSpec/DescribeClass
  describe "mysql_migration" do
    let(:steps) { instance_double(Morph::MysqlMigration::Steps) }

    before do
      Rails.application.load_tasks if Rake::Task.tasks.empty?
      allow(Morph::MysqlMigration::Steps).to receive(:new).and_return(steps)
    end

    after { Rake::Task.tasks.select { |t| t.name.start_with?("mysql_migration:") }.each(&:reenable) }

    it "passes DRY_RUN=1 through to the dump" do
      stub_const("ENV", ENV.to_h.merge("DRY_RUN" => "1"))
      allow(steps).to receive(:dump)

      Rake::Task["mysql_migration:dump"].execute

      expect(steps).to have_received(:dump).with(dry_run: true)
    end

    it "runs for real unless DRY_RUN is 1" do
      allow(steps).to receive(:restore)

      Rake::Task["mysql_migration:restore"].execute

      expect(steps).to have_received(:restore).with(dry_run: false)
    end

    it "stops the scrub with the reason when it is refused" do
      allow(steps).to receive(:scrub).and_raise(Morph::MysqlMigration::ScrubRefused, "refusing to scrub: not a rehearsal environment")

      expect { Rake::Task["mysql_migration:scrub"].execute }
        .to raise_error(SystemExit).and output(/refusing to scrub/).to_stderr
    end

    it "stops verification with each difference listed" do
      allow(steps).to receive(:verify).and_raise(Morph::MysqlMigration::VerificationFailed, ["owners: value hash differs"])

      expect { Rake::Task["mysql_migration:verify"].execute }
        .to raise_error(SystemExit).and output(/1 difference.*owners: value hash differs/m).to_stderr
    end

    it "verifies the retained scope unless told otherwise" do
      allow(steps).to receive(:verify).and_return([])

      expect { Rake::Task["mysql_migration:verify"].execute }.to output(/Verification passed/).to_stdout

      expect(steps).to have_received(:verify).with(scope: "retained")
    end
  end
end
