# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::PlatformFile do
  around do |example|
    Dir.mktmpdir("platform_file_spec") do |dir|
      @repo_path = dir
      example.run
    end
  end

  def write_platform(contents)
    File.write("#{@repo_path}/platform", contents)
  end

  describe ".read" do
    it "returns nil when there's no platform file at all" do
      expect(described_class.read(@repo_path)).to be_nil
    end

    it "returns the (chomped) contents of the platform file" do
      write_platform("heroku-24\n")
      expect(described_class.read(@repo_path)).to eq "heroku-24"
    end

    it "maps the legacy early_release value to heroku-24" do
      write_platform("early_release\n")
      expect(described_class.read(@repo_path)).to eq "heroku-24"
    end
  end
end
