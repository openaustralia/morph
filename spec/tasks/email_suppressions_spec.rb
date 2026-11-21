# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

# Runs the rake tasks against a fixture file of fictional addresses.
RSpec.describe "app:email_suppressions tasks" do # rubocop:disable RSpec/DescribeClass
  let(:csv) do
    <<~CSV
      address,date,output
      gone@example.org,2026-03-04 05:06:07,550 5.1.1 The email account that you tried to reach does not exist
      Mixed.Case@Example.org,2026-03-05,550-5.1.1 No such user
      blocked@example.org,2026-03-06,550 5.7.1 Our system has detected that this message is suspicious
      blocked-hyphen@example.org,2026-03-06,550-5.7.26 Unauthenticated sender
      silent@example.org,2026-03-07,
      ,2026-03-08,550 5.1.1 No such user
      <>,2026-03-09,550 5.1.1 No such user
    CSV
  end
  let(:file) { Tempfile.new(["export", ".csv"]).tap { |f| f.write(csv) && f.close } }

  before { Rails.application.load_tasks if Rake::Task.tasks.empty? }

  after { file.unlink }

  def run_task(name, *args)
    task = Rake::Task[name]
    task.reenable
    task.invoke(*args)
  end

  describe "import" do
    let(:name) { "app:email_suppressions:import" }

    it "suppresses addresses that hard-failed, as imported from Postal history" do
      expect { run_task(name, file.path) }.to output.to_stdout

      expect(EmailSuppression.active.order(:address).pluck(:address, :reason)).to eq(
        [["gone@example.org", "imported_from_postal"], ["mixed.case@example.org", "imported_from_postal"]]
      )
    end

    it "keeps the receiving server's reply and the date of the failure" do
      expect { run_task(name, file.path) }.to output.to_stdout

      suppression = EmailSuppression.find_by(address: "gone@example.org")
      expect(suppression.reply_excerpt).to start_with("550 5.1.1 The email account")
      expect(suppression.suppressed_at).to eq(Time.zone.parse("2026-03-04 05:06:07"))
    end

    it "leaves out refusals that blame our server, and rows with no reply" do
      expect { run_task(name, file.path) }.to output.to_stdout

      expect(EmailSuppression.where(address: %w[blocked@example.org blocked-hyphen@example.org silent@example.org])).to be_empty
    end

    it "prints counts only, never an address" do
      printed = capture_stdout { run_task(name, file.path) }

      expect(printed).to include("Suppressed: 2", "Already suppressed: 0", "Skipped refusal blaming our server: 2",
                                 "Skipped no reply: 1", "Skipped no address: 2")
      expect(printed).not_to include("example.org")
    end

    it "is safe to run twice" do
      expect { run_task(name, file.path) }.to output.to_stdout

      expect { run_task(name, file.path) }.to output(/Suppressed: 0.*Already suppressed: 2/m).to_stdout
      expect(EmailSuppression.count).to eq 2
    end

    it "doesn't suppress again an address someone has since had cleared, when the failure was before that" do
      EmailSuppression.suppress!("gone@example.org", reason: :hard_bounce, at: Time.zone.parse("2026-01-01"))
      EmailSuppression.lift!("gone@example.org")

      expect { run_task(name, file.path) }.to output.to_stdout

      expect(EmailSuppression.suppressed?("gone@example.org")).to be false
    end

    context "when the file starts with a byte order mark, as Excel's CSV UTF-8 does" do
      let(:csv) { "\uFEFFaddress,output\ngone@example.org,550 5.1.1 No such user\n" }

      it "reads the first column name correctly" do
        expect { run_task(name, file.path) }.to output(/Suppressed: 1/).to_stdout
      end
    end

    context "when the file has no address or reply column" do
      let(:csv) { "email,notes\nsomeone@example.org,hello\n" }

      it "stops and names the columns it needs, without importing anything" do
        expect { run_task(name, file.path) }.to raise_error(SystemExit).and output(/address.*output/).to_stderr
        expect(EmailSuppression.count).to eq 0
      end
    end
  end

  describe "lift" do
    let(:name) { "app:email_suppressions:lift" }

    it "clears the suppression whatever the case of the address given" do
      EmailSuppression.suppress!("gone@example.org", reason: :hard_bounce)

      expect { run_task(name, "Gone@Example.org") }.to output(/Lifted 1 suppression/).to_stdout
      expect(EmailSuppression.suppressed?("gone@example.org")).to be false
    end

    it "keeps the row as history, and a repeat hard bounce suppresses it again" do
      EmailSuppression.suppress!("gone@example.org", reason: :hard_bounce)
      expect { run_task(name, "gone@example.org") }.to output.to_stdout
      EmailSuppression.suppress!("gone@example.org", reason: :hard_bounce)

      expect(EmailSuppression.where(address: "gone@example.org").count).to eq 1
      expect(EmailSuppression.suppressed?("gone@example.org")).to be true
    end

    it "tells the operator how to use it when no address is given" do
      expect { run_task(name) }.to raise_error(SystemExit).and output(/Usage/).to_stderr
    end
  end

  def capture_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end
end
