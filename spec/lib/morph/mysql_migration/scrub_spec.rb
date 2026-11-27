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
      expect([first, second].flat_map { |o| [o.access_token, o.remember_token] }).to all(be_nil)
    end

    it "gives every owner a distinct random API key, never NULL, which would match a request with no key" do
      scrub.run!(client)

      keys = [first, second].map { |o| o.reload.api_key }
      expect(keys).to all(match(/\A\h{64}\z/))
      expect(keys.uniq.size).to eq 2
      expect(keys).not_to include("key-one", "key-two")
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

    it "replaces every variable value, which may hold a secret, with one fixed placeholder" do
      scraper = create(:scraper)
      variables = [create(:variable, scraper: scraper, value: "real-secret-1"), create(:variable, scraper: scraper, value: "real-secret-2")]

      result = scrub.run!(client)

      expect(variables.map { |v| v.reload.value }).to all(eq("scrubbed-for-rehearsal"))
      expect(result).to include("variables" => 2)
    end

    it "gives each suppressed address a distinct fictional one that cannot deliver" do
      suppressions = [create(:email_suppression, address: "real.person@example.com"), create(:email_suppression, address: "other@example.net")]

      result = scrub.run!(client)

      addresses = suppressions.map { |e| e.reload.address }
      expect(addresses).to eq(suppressions.map { |e| "suppressed-#{e.id}@example.invalid" })
      expect(addresses.uniq.size).to eq 2
      expect(result).to include("email_suppressions" => 2)
    end

    describe "#remaining_real_values" do
      before do
        create(:webhook)
        create(:variable, value: "real-secret")
        create(:email_suppression, address: "real.person@example.com")
      end

      it "reports what has not been scrubbed" do
        problems = scrub.remaining_real_values(client)

        expect(problems).to include(a_string_matching(/owners with an email that is not a placeholder/),
                                    a_string_matching(/owners with an access or remember token/),
                                    a_string_matching(/webhooks with a URL/),
                                    a_string_matching(/variables with a value/),
                                    a_string_matching(/suppressed addresses/))
      end

      it "reports nothing once the scrub has run" do
        scrub.run!(client)

        expect(scrub.remaining_real_values(client)).to be_empty
      end
    end

    it "reports how many owners it changed" do
      expect(scrub.run!(client)).to include("owners" => Owner.count)
    end
  end
end
