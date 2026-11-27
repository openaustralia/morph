# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::MysqlMigration::Scrub do
  subject(:scrub) { described_class.new(config: config) }

  let(:client) { ActiveRecord::Base.connection.raw_connection }
  let(:env) { { "MORPH_REHEARSAL" => "true" } }
  let(:config) { Morph::MysqlMigration::Config.new(env) }

  describe "#check_allowed!" do
    it "refuses unless the environment says it is a rehearsal one" do
      expect { described_class.new(config: Morph::MysqlMigration::Config.new({})).check_allowed! }
        .to raise_error(Morph::MysqlMigration::ScrubRefused, /not a rehearsal environment/)
    end

    it "refuses when the switch is anything but true" do
      expect { described_class.new(config: Morph::MysqlMigration::Config.new("MORPH_REHEARSAL" => "yes")).check_allowed! }
        .to raise_error(Morph::MysqlMigration::ScrubRefused)
    end

    it "refuses on production's server name even with the switch on" do
      production = Morph::MysqlMigration::Config.new("MORPH_REHEARSAL" => "true", "SERVER_NAME" => "Morph.io")

      expect { described_class.new(config: production).check_allowed! }.to raise_error(Morph::MysqlMigration::ScrubRefused, /production/)
    end

    it "allows the rehearsal host names" do
      rehearsal = Morph::MysqlMigration::Config.new("MORPH_REHEARSAL" => "true", "SERVER_NAME" => "new.morph.io")

      expect { described_class.new(config: rehearsal).check_allowed! }.not_to raise_error
    end
  end

  describe "#run!" do
    let!(:first) { create(:user, email: "first@example.com", access_token: "token-one", api_key: "key-one", remember_token: "remember-one") }
    let!(:second) { create(:user, email: "second@example.com", access_token: "token-two", api_key: "key-two", remember_token: nil) }

    it "does not touch the data when refused" do
      expect { described_class.new(config: Morph::MysqlMigration::Config.new({})).run!(client) }.to raise_error(Morph::MysqlMigration::ScrubRefused)

      expect(first.reload.email).to eq "first@example.com"
      expect(first.access_token).to eq "token-one"
    end

    it "replaces emails with distinct placeholders at an invalid domain and clears tokens" do
      scrub.run!(client)

      expect(first.reload.email).to eq "owner-#{first.id}@example.invalid"
      expect(second.reload.email).to eq "owner-#{second.id}@example.invalid"
      expect([first, second].flat_map { |o| [o.access_token, o.api_key, o.remember_token] }).to all(be_nil)
    end

    it "gives each webhook a distinct placeholder so the unique index holds" do
      scraper = create(:scraper)
      hooks = Array.new(3) { create(:webhook, scraper: scraper) }

      result = scrub.run!(client)

      urls = hooks.map { |h| h.reload.url }
      expect(urls).to all(start_with("https://example.invalid/webhooks/"))
      expect(urls.uniq.size).to eq 3
      expect(result).to include("webhooks" => 3)
    end

    it "reports how many owners it changed" do
      expect(scrub.run!(client)).to include("owners" => Owner.count)
    end
  end
end
