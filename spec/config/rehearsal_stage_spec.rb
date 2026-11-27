# typed: false
# frozen_string_literal: true

require "spec_helper"
require "rake"

# Guards for the rehearsal stage (#1587). The deploy itself needs a real server, so
# these evaluate the stage files against a recording stand-in for the Capistrano
# DSL and check that the stages cannot drift into the risks flagged in the cutover
# runbook. The rehearsal stage is retired at cutover: delete this file with it, and
# change the no production stage example when the cutover merge adds production.rb.
describe "Capistrano stages" do # rubocop:disable RSpec/DescribeClass
  # Collects what a stage file sets without needing Capistrano loaded
  let(:recorder_class) do
    Class.new do
      attr_reader :settings, :roles

      def initialize
        @settings = {}
        @roles = []
      end

      def set(key, value)
        @settings[key] = value
      end

      def role(name, hosts)
        @roles << [name, hosts]
      end

      # The local stage defines a task and a hook, which these checks ignore
      def before(*); end
      def task(*); end
    end
  end

  def stage_settings(name)
    recorder = recorder_class.new
    recorder.instance_eval(Rails.root.join("config/deploy/#{name}.rb").read, "config/deploy/#{name}.rb")
    recorder
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("STAGING_DEPLOY_TO").and_return("staging.example.invalid")
    # Stand-ins for the capistrano-tagging3 tasks the rehearsal stage silences
    %w[tagging3:deploy tagging3:cleanup].each do |name|
      Rake::Task.define_task(name) { raise "should not run" }
    end
  end

  it "has no production stage until the cutover merge" do
    expect(Rails.root.join("config/deploy/production.rb")).not_to exist
  end

  describe "rehearsal" do
    it "deploys to new.morph.io by hostname with the production Rails environment" do
      stage = stage_settings("rehearsal")
      expect(stage.settings).to include(stage: :rehearsal, rails_env: :production)
      expect(stage.roles.flat_map(&:last).flatten.uniq).to eq(["deploy@new.morph.io"])
    end

    it "uses rbenv and /srv/www/rehearsal" do
      settings = stage_settings("rehearsal").settings
      expect(settings).to include(rbenv_type: :user, deploy_to: "/srv/www/rehearsal")
      expect(settings[:rbenv_ruby]).to eq(Rails.root.join(".ruby-version").read.strip)
    end

    it "skips the post-deploy queue fix, which would run real scrapers from a restored database" do
      expect(stage_settings("rehearsal").settings).to include(fix_queue_run_inconsistencies: false)
      expect(Rails.root.join("config/deploy.rb").read).to include("next unless fetch(:fix_queue_run_inconsistencies, true)")
    end

    it "pushes no deploy tags, and only the tagging tasks are emptied" do
      stage_settings("rehearsal")
      expect(Rake::Task["tagging3:deploy"].actions).to be_empty
      expect(Rake::Task["tagging3:cleanup"].actions).to be_empty
    end
  end

  %w[staging local].each do |name|
    describe name do
      it "does not override the rvm and /var/www defaults" do
        keys = stage_settings(name).settings.keys
        expect(keys).not_to include(:deploy_to, :rbenv_type, :rbenv_ruby)
      end
    end
  end

  describe "deploy.rb defaults" do
    let(:deploy_rb) { Rails.root.join("config/deploy.rb").read }

    it "keeps rvm and /var/www for the stages that do not override them" do
      expect(deploy_rb).to include('set :rvm_ruby_version, "ruby-3.0.7"')
      expect(deploy_rb).to include('set :deploy_to, "/var/www"')
    end

    it "does not set rbenv for every stage" do
      expect(deploy_rb).not_to include("set :rbenv")
    end
  end

  describe "Capfile" do
    let(:capfile) { Rails.root.join("Capfile").read }

    it "drops the Honeybadger deploy hook" do
      expect(capfile).not_to match(%r{^require "capistrano/honeybadger"})
    end

    it "loads rbenv only for the stages that use it and rvm for the others" do
      expect(capfile).to include("RBENV_STAGES = %w[rehearsal production].freeze")
      expect(capfile).to match(%r{if ARGV\.intersect\?\(RBENV_STAGES\)\n\s+require "capistrano/rbenv"\nelse\n\s+require "capistrano/rvm"\nend})
    end
  end

  describe "env-rehearsal-example" do
    let(:lines) { Rails.root.join("env-rehearsal-example").read.lines.map(&:strip).reject { |l| l.empty? || l.start_with?("#") } }

    it "sends mail to a local sink with no credentials" do
      expect(lines).to include("SMTP_SERVER=127.0.0.1")
      expect(lines.grep(/\ASMTP_(USERNAME|PASSWORD)=/)).to be_empty
    end

    it "sets no keys the rehearsal server must not have" do
      expect(lines.grep(/HONEYBADGER|STRIPE|HEAP|GOOGLE_ANALYTICS|AWS|CRON_ENABLED/)).to be_empty
    end
  end
end
