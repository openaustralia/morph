# typed: false
# frozen_string_literal: true

require "spec_helper"

# Guards for the rehearsal stage (#1587). The deploy itself needs a real server,
# so these only check that the files cannot drift into the risks flagged in the
# cutover runbook.
describe "rehearsal stage" do # rubocop:disable RSpec/DescribeClass
  let(:root) { Rails.root }

  it "has no production stage until the cutover merge" do
    expect(root.join("config/deploy/production.rb")).not_to exist
  end

  it "deploys to new.morph.io by hostname with the production Rails environment" do
    stage = root.join("config/deploy/rehearsal.rb").read
    expect(stage).to include("set :stage, :rehearsal")
    expect(stage).to include("set :rails_env, :production")
    expect(stage.scan(/deploy@[^\s"\]]+/).uniq).to eq(["deploy@new.morph.io"])
  end

  it "skips the post-deploy queue fix, which would run real scrapers from a restored database" do
    expect(root.join("config/deploy/rehearsal.rb").read).to include("set :fix_queue_run_inconsistencies, false")
    expect(root.join("config/deploy.rb").read).to include("next unless fetch(:fix_queue_run_inconsistencies, true)")
  end

  it "keeps the deploy path per stage so cutover can rename the directory" do
    expect(root.join("config/deploy.rb").read).to include("set :deploy_to, -> { \"/srv/www/\#{fetch(:stage)}\" }")
  end

  it "drops the Honeybadger deploy hook and uses rbenv" do
    capfile = root.join("Capfile").read
    expect(capfile).not_to match(%r{^require "capistrano/honeybadger"})
    expect(capfile).to match(%r{^require "capistrano/rbenv"})
  end

  it "rewrites the links as relative links after publishing" do
    expect(root.join("lib/capistrano/tasks/relative_symlinks.cap").read).to include('after "deploy:symlink:release", "deploy:relative_symlinks"')
  end

  describe "env-rehearsal-example" do
    let(:lines) { root.join("env-rehearsal-example").read.lines.map(&:strip).reject { |l| l.empty? || l.start_with?("#") } }

    it "sends mail to a local sink with no credentials" do
      expect(lines).to include("SMTP_SERVER=127.0.0.1")
      expect(lines.grep(/\ASMTP_(USERNAME|PASSWORD)=/)).to be_empty
    end

    it "sets no keys the rehearsal server must not have" do
      expect(lines.grep(/HONEYBADGER|STRIPE|HEAP|GOOGLE_ANALYTICS|AWS|CRON_ENABLED/)).to be_empty
    end
  end
end
