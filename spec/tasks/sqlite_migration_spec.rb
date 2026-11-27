# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"
require "tmpdir"

RSpec.describe "tasks" do # rubocop:disable RSpec/DescribeClass
  describe "sqlite_migration", type: :integration do
    before { Rails.application.load_tasks if Rake::Task.tasks.empty? }

    def run_task(name)
      Rake::Task[name].reenable
      Rake::Task[name].invoke
    end

    def with_env(vars)
      old = vars.keys.index_with { |k| ENV.fetch(k, nil) }
      vars.each { |k, v| ENV[k] = v }
      yield
    ensure
      old.each { |k, v| ENV[k] = v }
    end

    describe "app:sqlite_migration:bulk and delta" do
      let(:result) do
        Morph::SqliteMigration::Sync::Result.new(
          mode: :bulk, source: "old.example.org:/x/", destination: "/y/", exit_status: 0, elapsed_seconds: 2.0,
          files_transferred: 3, file_bytes: 10, wire_bytes: 4_000_000, total_file_bytes: 99, warning: "careful"
        )
      end
      let(:sync) { instance_double(Morph::SqliteMigration::Sync, command: ["rsync"], display_command: "rsync a b", run: result) }

      before { allow(Morph::SqliteMigration::Sync).to receive(:new).and_return(sync) }

      it "builds the copy from the environment and prints elapsed time and speed" do
        with_env("SQLITE_SOURCE" => "old.example.org:/x", "SQLITE_DESTINATION" => "/y", "DRY_RUN" => "1", "BWLIMIT_KBPS" => "100") do
          expect { run_task("app:sqlite_migration:bulk") }
            .to output(%r{Elapsed:\s+2.0 s.*Transfer speed:\s+2.0 MB/s.*Warning:\s+careful}m).to_stdout
        end

        expect(Morph::SqliteMigration::Sync).to have_received(:new).with(
          hash_including(source: "old.example.org:/x", destination: "/y", mode: :bulk, dry_run: true, bwlimit: 100, delete: false)
        )
      end

      it "passes delete and its limit to the delta pass, and appends a record to LOG_FILE" do
        Dir.mktmpdir do |dir|
          log = File.join(dir, "move.jsonl")
          with_env("SQLITE_SOURCE" => "/x", "SQLITE_DESTINATION" => "/y", "DELETE" => "1", "MAX_DELETE" => "10", "LOG_FILE" => log) do
            expect { run_task("app:sqlite_migration:delta") }.to output(/Recorded in/).to_stdout
          end

          expect(JSON.parse(File.read(log))).to include("mode" => "bulk", "elapsed_seconds" => 2.0)
        end

        expect(Morph::SqliteMigration::Sync).to have_received(:new).with(
          hash_including(mode: :delta, delete: true, max_delete: 10)
        )
      end

      it "aborts with the reason when the copy is refused" do
        allow(Morph::SqliteMigration::Sync).to receive(:new).and_raise(Morph::SqliteMigration::Sync::Error, "source is required")

        with_env("SQLITE_SOURCE" => "", "SQLITE_DESTINATION" => "") do
          expect { run_task("app:sqlite_migration:bulk") }
            .to raise_error(SystemExit).and output(/bulk copy failed: source is required/).to_stderr
        end
      end
    end

    describe "app:sqlite_migration:manifest and verify" do
      it "writes a manifest, and verify matches two identical ones" do
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "tree/data/jane/one"))
          File.write(File.join(dir, "tree/data/jane/one/data.sqlite"), "abc")
          output = File.join(dir, "manifest.tsv")

          with_env("DIR" => File.join(dir, "tree"), "OUTPUT" => output) do
            expect { run_task("app:sqlite_migration:manifest") }.to output(/Wrote 1 files/).to_stdout
          end
          expect(File.read(output)).to eq("data/jane/one/data.sqlite\t3\n")

          with_env("SOURCE_MANIFEST" => output, "DESTINATION_MANIFEST" => output) do
            expect { run_task("app:sqlite_migration:verify") }.to output(/RESULT: match/).to_stdout
          end
        end
      end

      it "prints the manifest to stdout when there is no OUTPUT" do
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "a"), "xy")

          with_env("DIR" => dir, "OUTPUT" => nil) do
            expect { run_task("app:sqlite_migration:manifest") }.to output("a\t2\n").to_stdout
          end
        end
      end

      it "exits 1 when the manifests differ" do
        Dir.mktmpdir do |dir|
          File.write(File.join(dir, "source.tsv"), "a\t1\n")
          File.write(File.join(dir, "destination.tsv"), "a\t2\n")

          with_env("SOURCE_MANIFEST" => File.join(dir, "source.tsv"), "DESTINATION_MANIFEST" => File.join(dir, "destination.tsv")) do
            expect { run_task("app:sqlite_migration:verify") }
              .to raise_error(SystemExit) { |e| expect(e.status).to eq(1) }.and output(/RESULT: MISMATCH/).to_stdout
          end
        end
      end
    end
  end
end
