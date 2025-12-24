# typed: false
# frozen_string_literal: true

require "spec_helper"
require_relative "../../../lib/tasks/support/db_backup_utils"

RSpec.describe DbBackupUtils do
  describe "tool availability" do
    it "has mysqldump available (REQUIRED)" do
      expect(mysqldump_available?).to be(true), "mysqldump is required but not found in PATH"
    end

    it "checks for zstd availability" do
      require_zstd
      expect(zstd_available?).to be true
      # if zstd_available?
      #   expect(zstd_available?).to be true
      # else
      #   skip "zstd not installed - compression tests will be skipped"
      # end
    end
  end

  describe ".mysqldump_cmd" do
    it "restores MYSQL_PWD environment variable after block execution" do
      original_pwd = ENV.fetch("MYSQL_PWD", nil)

      described_class.mysqldump_cmd { |_cmd| nil }

      expect(ENV.fetch("MYSQL_PWD", nil)).to eq(original_pwd)
    end

    it "restores MYSQL_PWD even when block raises error" do
      original_pwd = ENV.fetch("MYSQL_PWD", nil)

      expect do
        described_class.mysqldump_cmd { raise "test error" }
      end.to raise_error("test error")

      expect(ENV.fetch("MYSQL_PWD", nil)).to eq(original_pwd)
    end
  end

  # describe ".dump_compressed" do
  #   let(:output_file) { "tmp/test_dump_#{Time.now.to_i}.sql.zst" }
  #   let(:tables) { "owners" }
  #
  #   before do
  #     require_zstd
  #     # Ensure we have a user to dump
  #     create(:user)
  #   end
  #
  #   after do
  #     FileUtils.rm_f(output_file)
  #   end

  # it "creates a compressed backup file" do
  #   described_class.dump_compressed("--no-data", tables, output_file)
  #
  #   expect(File.exist?(output_file)).to be true
  #   expect(File.size(output_file)).to be > 0
  # end

  # it "creates valid zstd compressed data that can be decompressed" do
  #   described_class.dump_compressed("--no-data", tables, output_file)
  #
  #   # Decompress and verify it's valid SQL
  #   decompressed = `zstd -dc #{output_file}`
  #   expect(decompressed).to include("CREATE TABLE")
  #   expect(decompressed).to include("owners")
  # end

  # it "includes mysqldump header comments" do
  #   described_class.dump_compressed("--no-data", tables, output_file)
  #
  #   decompressed = `zstd -dc #{output_file}`
  #   expect(decompressed).to match(/^-- MySQL dump/)
  #   expect(decompressed).to match(/^-- Server version/)
  # end

  # it "includes table data when not using --no-data" do
  #   user = create(:user, nickname: "test_backup_user")
  #
  #   described_class.dump_compressed("", tables, output_file)
  #
  #   decompressed = `zstd -dc #{output_file}`
  #   expect(decompressed).to include("INSERT INTO")
  #   expect(decompressed).to include("test_backup_user")
  # end

  #   it "appends to existing file when append: true" do
  #     # Create initial file
  #     described_class.dump_compressed("--no-data", tables, output_file)
  #     initial_size = File.size(output_file)
  #
  #     # Append more data
  #     described_class.dump_compressed("--no-data", tables, output_file, append: true)
  #     final_size = File.size(output_file)
  #
  #     expect(final_size).to be > initial_size
  #   end
  #
  #   it "handles array of tables" do
  #     tables_array = ["owners", "scrapers"]
  #
  #     described_class.dump_compressed("--no-data", tables_array, output_file)
  #
  #     decompressed = `zstd -dc #{output_file}`
  #     expect(decompressed).to include("CREATE TABLE `owners`")
  #     expect(decompressed).to include("CREATE TABLE `scrapers`")
  #   end
  #
  #   it "aborts on mysqldump failure" do
  #     # Use invalid table name to cause failure
  #     expect do
  #       described_class.dump_compressed("", "nonexistent_table_xyz", output_file)
  #     end.to raise_error(SystemExit)
  #   end
  # end

  describe ".dump_with_id_batches" do
    let(:output_file) { "tmp/test_batch_dump_#{Time.now.to_i}.sql" }
    let(:compressed_file) { "#{output_file}.zst" }
    let(:table) { "owners" }
    let(:column) { "id" }

    after do
      FileUtils.rm_f(output_file)
      FileUtils.rm_f(compressed_file)
    end

    context "without compression" do
      it "creates empty file for empty ids without append" do
        described_class.dump_with_id_batches(table, column, [], output_file, append: false)

        expect(File.exist?(output_file)).to be true
        expect(File.size(output_file)).to eq(0)
      end

      it "does nothing for empty ids with append" do
        described_class.dump_with_id_batches(table, column, [], output_file, append: true)

        expect(File.exist?(output_file)).to be false
      end

      # FIXME: freezes on dev system even though rake task doesn't
      # it "dumps records with specified ids only" do
      #   user1 = create(:user)
      #   user2 = create(:user)
      #   user3 = create(:user)
      #
      #   described_class.dump_with_id_batches(table, column, [user1.id, user3.id], output_file)
      #
      #   content = File.read(output_file)
      #   expect(content).to include("CREATE TABLE")
      #   expect(content).to include("INSERT INTO")
      #   expect(content).to include(user1.nickname)
      #   expect(content).to include(user3.nickname)
      #   expect(content).not_to include(user2.nickname)
      # end

      # FIXME: freezes on dev system even though rake task doesn't
      # it "creates valid SQL with standard mysqldump structure" do
      #   user = create(:user)
      #
      #   described_class.dump_with_id_batches(table, column, [user.id], output_file)
      #
      #   content = File.read(output_file)
      #   # Check for standard mysqldump structure
      #   expect(content).to match(/^-- MySQL dump/)
      #   expect(content).to include("DROP TABLE IF EXISTS")
      #   expect(content).to include("CREATE TABLE")
      #   expect(content).to include("LOCK TABLES")
      #   expect(content).to include("UNLOCK TABLES")
      # end

      # FIXME: freezes on dev system even though rake task doesn't
      # it "splits into multiple batches for large id lists" do
      #   # Create enough IDs to exceed 800 char limit
      #   ids = (1..150).to_a
      #
      #   # Should not raise error even with large batch
      #   expect do
      #     described_class.dump_with_id_batches(table, column, ids, output_file)
      #   end.not_to raise_error
      #
      #   # File should contain CREATE TABLE (only once since it's the first batch)
      #   content = File.read(output_file)
      #   expect(content.scan(/CREATE TABLE `#{tables}`/).count).to eq(1)
      # end

      # FIXME: freezes on dev system even though rake task doesn't
      # it "appends to existing file when append: true" do
      #   user1 = create(:user)
      #   user2 = create(:user)
      #
      #   # First dump
      #   described_class.dump_with_id_batches(table, column, [user1.id], output_file, append: false)
      #   initial_content = File.read(output_file)
      #
      #   # Append second dump
      #   described_class.dump_with_id_batches(table, column, [user2.id], output_file, append: true)
      #   final_content = File.read(output_file)
      #
      #   # Should have both users
      #   expect(final_content).to include(user1.nickname)
      #   expect(final_content).to include(user2.nickname)
      #   expect(final_content.length).to be > initial_content.length
      # end
    end

    # FIXME: freezes on dev system even though rake task doesn't
    # context "with compression" do
    #   before do
    #     require_zstd
    #   end
    #
    #   it "creates compressed output when compress: true" do
    #     user = create(:user)
    #
    #     described_class.dump_with_id_batches(table, column, [user.id], compressed_file, compress: true)
    #
    #     expect(File.exist?(compressed_file)).to be true
    #
    #     # Verify it's compressed and contains the data
    #     decompressed = `zstd -dc #{compressed_file}`
    #     expect(decompressed).to include(user.nickname)
    #     expect(decompressed).to include("CREATE TABLE")
    #   end
    # end
  end

  describe ".dump_batch" do
    let(:output_file) { "tmp/test_single_batch_#{Time.now.to_i}.sql" }
    let(:compressed_file) { "#{output_file}.zst" }
    let(:table) { "owners" }
    let(:column) { "id" }

    after do
      FileUtils.rm_f(output_file)
      FileUtils.rm_f(compressed_file)
    end

    it "does nothing for empty ids" do
      described_class.dump_batch(table, column, [], output_file, true, false)

      expect(File.exist?(output_file)).to be false
    end

    # FIXME: freezes on dev system even though rake task doesn't
    # it "includes CREATE TABLE for first batch" do
    #   user = create(:user)
    #
    #   described_class.dump_batch(table, column, [user.id], output_file, true, false)
    #
    #   content = File.read(output_file)
    #   expect(content).to include("CREATE TABLE")
    #   expect(content).to include("DROP TABLE IF EXISTS")
    # end

    # FIXME: freezes on dev system even though rake task doesn't
    # it "excludes CREATE TABLE for subsequent batches" do
    #   user1 = create(:user)
    #   user2 = create(:user)
    #
    #   # First batch with CREATE TABLE
    #   described_class.dump_batch(table, column, [user1.id], output_file, true, false)
    #
    #   # Second batch without CREATE TABLE
    #   described_class.dump_batch(table, column, [user2.id], output_file, false, false)
    #
    #   content = File.read(output_file)
    #   # Should have only one CREATE TABLE
    #   expect(content.scan(/CREATE TABLE `#{table}`/).count).to eq(1)
    #   # But should have both users
    #   expect(content).to include(user1.nickname)
    #   expect(content).to include(user2.nickname)
    # end

    # context "with compression" do
    #   before do
    #     require_zstd
    #   end

    # FIXME: freezes on dev system even though rake task doesn't
    # it "uses compression when compress: true" do
    #   user = create(:user)
    #
    #   described_class.dump_batch(table, column, [user.id], compressed_file, true, true)
    #
    #   expect(File.exist?(compressed_file)).to be true
    #
    #   decompressed = `zstd -dc #{compressed_file}`
    #   expect(decompressed).to include(user.nickname)
    # end
    # end

    it "aborts on mysqldump failure" do
      expect do
        described_class.dump_batch("nonexistent_table", column, [999], output_file, true, false)
      end.to raise_error(SystemExit)
    end
  end

  describe ".puts_help" do
    let(:backup_file) { "tmp/test_backup_for_help.sql.zst" }

    before do
      FileUtils.mkdir_p("tmp")
      File.write(backup_file, "x" * 1_048_576) # 1 MB
    end

    after do
      FileUtils.rm_f(backup_file)
    end

    it "displays backup file information" do
      expect { described_class.puts_help(backup_file) }
        .to output(/Created #{Regexp.escape(backup_file)}/).to_stdout
    end

    it "displays file size in human readable format" do
      expect { described_class.puts_help(backup_file) }
        .to output(/1(\.\d+)?\s*(MB|MiB)/i).to_stdout
    end

    it "displays restore instructions" do
      output = capture_stdout { described_class.puts_help(backup_file) }

      expect(output).to include("To restore this backup:")
      expect(output).to include("bundle exec rake db:drop db:create")
      expect(output).to include("zstd -dc #{backup_file}")
      expect(output).to include("bundle exec rails db -p")
    end

    it "handles small files" do
      small_file = "tmp/small_backup.sql.zst"
      File.write(small_file, "test")

      expect { described_class.puts_help(small_file) }
        .to output(/\d+\s*(B|bytes)/i).to_stdout

      FileUtils.rm_f(small_file)
    end
  end
end
