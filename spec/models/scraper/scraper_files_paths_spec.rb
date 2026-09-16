# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Scraper do
  let(:user) { create(:user) }

  # ============================================================================
  # FILE PATHS & DIRECTORIES
  # ============================================================================

  describe "#repo_path and #data_path" do
    let(:owner) { create(:user) }
    let(:scraper) { build(:scraper, name: "my_scraper", owner: owner) }

    it "returns correct repo path" do
      expect(scraper.repo_path).to eq("#{owner.repo_root}/my_scraper")
    end

    it "returns correct data path" do
      expect(scraper.data_path).to eq("#{owner.data_root}/my_scraper")
    end
  end

  describe "#destroy_repo_and_data" do
    let(:scraper) { build(:scraper) }

    before do
      FileUtils.mkdir_p(scraper.repo_path)
      FileUtils.mkdir_p(scraper.data_path)
      FileUtils.touch(File.join(scraper.repo_path, "test.txt"))
      FileUtils.touch(File.join(scraper.data_path, "data.db"))
    end

    it "removes repo and data directories" do
      scraper.destroy_repo_and_data

      expect(File.exist?(scraper.repo_path)).to be false
      expect(File.exist?(scraper.data_path)).to be false
    end
  end

  # ============================================================================
  # README FILES
  # ============================================================================

  describe "#readme" do
    let(:scraper) { build(:scraper) }

    before do
      FileUtils.mkdir_p(scraper.repo_path)
    end

    after do
      FileUtils.rm_rf(scraper.repo_path)
    end

    it "returns nil when no README file exists" do
      expect(scraper.readme).to be_nil
    end

    it "renders README content as HTML when README.md exists" do
      readme_path = File.join(scraper.repo_path, "README.md")
      File.write(readme_path, "# Test README")

      rendered = scraper.readme
      expect(rendered).to include("Test README")
    end
  end

  describe "#readme_filename" do
    let(:scraper) { build(:scraper) }

    before do
      FileUtils.mkdir_p(scraper.repo_path)
      File.write(File.join(scraper.repo_path, "README.md"), "content")
    end

    after do
      FileUtils.rm_rf(scraper.repo_path)
    end

    it "returns the basename of the README file" do
      expect(scraper.readme_filename).to eq("README.md")
    end
  end

  describe "#readme_url" do
    let(:scraper) { build(:scraper, repo_url: "https://github.com/owner/repo") }

    before do
      FileUtils.mkdir_p(scraper.repo_path)
      File.write(File.join(scraper.repo_path, "README.md"), "content")
    end

    after do
      FileUtils.rm_rf(scraper.repo_path)
    end

    it "returns GitHub URL for the README file" do
      expect(scraper.readme_url).to eq("https://github.com/owner/repo/blob/main/README.md")
    end
  end

  # ============================================================================
  # LANGUAGE & SCRAPER FILES
  # ============================================================================

  describe "#language" do
    let(:scraper) { build(:scraper) }

    it "delegates to Morph::Language.language" do
      language = instance_double(Morph::Language)
      allow(Morph::Language).to receive(:language).with(scraper.repo_path).and_return(language)

      expect(scraper.language).to eq(language)
    end
  end

  describe "#main_scraper_filename" do
    let(:scraper) { build(:scraper) }
    let(:language) { instance_double(Morph::Language, scraper_filename: "scraper.rb") }

    it "returns scraper filename from language" do
      allow(scraper).to receive(:language).and_return(language)
      expect(scraper.main_scraper_filename).to eq("scraper.rb")
    end

    it "returns nil when no language detected" do
      allow(scraper).to receive(:language).and_return(nil)
      expect(scraper.main_scraper_filename).to be_nil
    end
  end

  describe "#file_url" do
    let(:scraper) { build(:scraper, repo_url: "https://github.com/owner/repo") }

    it "returns GitHub blob URL for given file" do
      url = scraper.file_url("scraper.rb")
      expect(url).to eq("https://github.com/owner/repo/blob/main/scraper.rb")
    end
  end

  describe "#main_scraper_file_url" do
    let(:scraper) { build(:scraper, repo_url: "https://github.com/owner/repo") }

    it "returns GitHub URL for main scraper file" do
      allow(scraper).to receive(:main_scraper_filename).and_return("scraper.py")
      expect(scraper.main_scraper_file_url).to eq("https://github.com/owner/repo/blob/main/scraper.py")
    end

    it "returns nil when no main scraper filename" do
      allow(scraper).to receive(:main_scraper_filename).and_return(nil)
      expect(scraper.main_scraper_file_url).to be_nil
    end
  end

  # ============================================================================
  # DATABASE & PLATFORM
  # ============================================================================

  describe "#database" do
    let(:scraper) { build(:scraper) }

    it "returns a Morph::Database instance" do
      db = scraper.database
      expect(db).to be_a(Morph::Database)
    end
  end

  describe "#platform" do
    let(:scraper) { build(:scraper) }

    before do
      FileUtils.rm_rf(scraper.repo_path)
      FileUtils.mkdir_p(scraper.repo_path)
    end

    it "returns nil if no platform file is present" do
      expect(scraper.platform).to be_nil
    end

    it "returns the platform if the file is present" do
      File.write(File.join(scraper.repo_path, "platform"), "heroku-99")
      expect(scraper.platform).to eq "heroku-99"
    end

    it "converts early_release to heroku-24" do
      File.write(File.join(scraper.repo_path, "platform"), "early_release")
      expect(scraper.platform).to eq "heroku-24"
    end
  end

  # ============================================================================
  # UTILITY METHODS
  # ============================================================================

  describe "#git_url_https" do
    it "converts git protocol to https" do
      scraper = build(:scraper, git_url: "git://github.com/owner/repo.git")
      expect(scraper.git_url_https).to eq("https://github.com/owner/repo.git")
    end

    it "converts an ssh clone url to https" do
      scraper = build(:scraper, git_url: "git@github.com:owner/repo.git")
      expect(scraper.git_url_https).to eq("https://github.com/owner/repo.git")
    end

    it "leaves an https clone url alone" do
      scraper = build(:scraper, git_url: "https://gitlab.com/owner/repo.git")
      expect(scraper.git_url_https).to eq("https://gitlab.com/owner/repo.git")
    end
  end

  describe "#default_branch" do
    let(:scraper) { build(:scraper) }

    after { FileUtils.rm_rf(scraper.repo_path) }

    it "is main until the repository has been cloned" do
      expect(scraper.default_branch).to eq("main")
    end

    it "is whatever the local clone has checked out" do
      FileUtils.mkdir_p(File.join(scraper.repo_path, ".git"))
      File.write(File.join(scraper.repo_path, ".git", "HEAD"), "ref: refs/heads/trunk\n")

      expect(scraper.default_branch).to eq("trunk")
    end

    it "is main when HEAD is detached" do
      FileUtils.mkdir_p(File.join(scraper.repo_path, ".git"))
      File.write(File.join(scraper.repo_path, ".git", "HEAD"), "0123456789abcdef0123456789abcdef01234567\n")

      expect(scraper.default_branch).to eq("main")
    end
  end

  describe "#original_language" do
    let(:scraper) { build(:scraper) }

    it "returns Morph::Language for valid language key" do
      scraper.original_language_key = "ruby"
      language = scraper.original_language
      expect(language).to be_a(Morph::Language)
    end

    it "returns nil when no language key" do
      scraper.original_language_key = nil
      expect(scraper.original_language).to be_nil
    end
  end
end
