# typed: false
# frozen_string_literal: true

# Every Forge adapter has to satisfy this, so GitLab (PR 4) and GitHub are
# held to the same contract. `forge` is the adapter under test; `owner` an
# Owner with an identity on it; `scraper` a Scraper of that owner on that
# forge, with repo_url set.
RSpec.shared_examples "a forge" do
  it "is registered under its key" do
    expect(Morph::Forge.for(forge.key)).to be_a(forge.class)
  end

  it "has a human name" do
    expect(forge.name).to be_present
  end

  describe "URLs" do
    it "points at the owner on the forge" do
      expect(forge.owner_url(owner)).to match(%r{\Ahttps://}).and include(owner.forge_identity(forge.key).login)
    end

    it "points at a file on the repository's default branch" do
      allow(scraper).to receive(:default_branch).and_return("trunk")

      expect(forge.file_url(scraper, "scraper.rb")).to start_with(scraper.repo_url).and include("trunk").and end_with("scraper.rb")
    end

    it "points at a commit" do
      expect(forge.commit_url(scraper, "abc1234")).to start_with(scraper.repo_url).and end_with("abc1234")
    end
  end

  describe "errors" do
    it "explains every kind of repository access failure in words a user can act on" do
      Morph::Forge::Error::KINDS.each do |kind|
        error = forge.error(kind, scraper)

        expect(error).to be_a(Morph::Forge::Error)
        expect(error.kind).to eq(kind)
        expect(error.message).to be_present
        expect(error.message_html).to be_present
      end
    end
  end
end
