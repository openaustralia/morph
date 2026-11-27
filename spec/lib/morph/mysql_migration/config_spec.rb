# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::Config do
  let(:env) do
    {
      "MYSQL_MIGRATION_SOURCE_URL" => "mysql2://u:p@old.example.invalid:3306/scraping_production",
      "MYSQL_MIGRATION_TARGET_URL" => "mysql2://u:p@localhost:3306/scraping_production"
    }
  end

  it "requires both servers to be named, with no defaults" do
    expect { described_class.new({}).source }.to raise_error(/MYSQL_MIGRATION_SOURCE_URL needs to be set/)
    expect { described_class.new(env.except("MYSQL_MIGRATION_TARGET_URL")).target }.to raise_error(/MYSQL_MIGRATION_TARGET_URL needs to be set/)
  end

  it "refuses a target that is the source" do
    same = env.merge("MYSQL_MIGRATION_TARGET_URL" => env["MYSQL_MIGRATION_SOURCE_URL"])

    expect { described_class.new(same).target }.to raise_error(/same database/)
  end

  it "does not need the source once the old server has been stopped" do
    expect(described_class.new(env.except("MYSQL_MIGRATION_SOURCE_URL")).target.host).to eq "localhost"
  end

  it "reads integers and rejects bad ones" do
    expect(described_class.new(env).threads).to eq 4
    expect(described_class.new(env.merge("MYSQL_MIGRATION_THREADS" => "8")).threads).to eq 8
    expect(described_class.new(env).backfill_threads).to eq 1
    expect { described_class.new(env.merge("MYSQL_MIGRATION_THREADS" => "0")).threads }.to raise_error(/positive/)
    expect { described_class.new(env.merge("MYSQL_MIGRATION_THREADS" => "lots")).threads }.to raise_error(ArgumentError)
  end

  describe "#s3_options" do
    it "passes only the settings that are present and never reads credentials" do
      config = described_class.new(env.merge("MYSQL_MIGRATION_S3_BUCKET" => "example-archive", "MYSQL_MIGRATION_S3_REGION" => "ap-southeast-2",
                                             "AWS_SECRET_ACCESS_KEY" => "not-read"))

      expect(config.s3_options).to eq("s3BucketName" => "example-archive", "s3Region" => "ap-southeast-2")
    end

    it "requires a bucket" do
      expect { described_class.new(env).s3_options }.to raise_error(/MYSQL_MIGRATION_S3_BUCKET/)
    end
  end

  it "can use a local directory for the archive instead of S3 when practising" do
    config = described_class.new(env.merge("MYSQL_MIGRATION_ARCHIVE_DIR" => "/srv/practice"))

    expect(config.local_archive?).to be true
    expect(config.archive_base_url).to eq "/srv/practice"
    expect(config.s3_options).to eq({})
  end

  it "uses the S3 prefix as the archive location otherwise" do
    expect(described_class.new(env.merge("MYSQL_MIGRATION_S3_PREFIX" => "archive")).archive_base_url).to eq "archive"
  end

  it "tidies the S3 prefix" do
    expect(described_class.new(env.merge("MYSQL_MIGRATION_S3_PREFIX" => "/archive/log_lines/")).s3_prefix).to eq "archive/log_lines"
  end

  describe "#rehearsal?" do
    it "is true only when MORPH_REHEARSAL is exactly true" do
      expect(described_class.new(env).rehearsal?).to be false
      expect(described_class.new(env.merge("MORPH_REHEARSAL" => "1")).rehearsal?).to be false
      expect(described_class.new(env.merge("MORPH_REHEARSAL" => "true")).rehearsal?).to be true
    end
  end
end
