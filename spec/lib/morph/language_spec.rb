# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::Language do
  let(:ruby) { described_class.new(:ruby) }
  let(:python) { described_class.new(:python) }
  let(:php) { described_class.new(:php) }
  let(:perl) { described_class.new(:perl) }

  describe "#human" do
    it { expect(ruby.human).to eq "Ruby" }
    it { expect(python.human).to eq "Python" }
    it { expect(php.human).to eq "PHP" }
    it { expect(perl.human).to eq "Perl" }
  end

  describe "#scraper_templates" do
    it { expect(ruby.scraper_templates.keys.sort).to eq %w[.rubocop.yml .ruby-version Gemfile Gemfile.lock platform scraper.rb] }

    it do
      expect(ruby.scraper_templates["scraper.rb"]).to eq File.read("default_files/ruby/template/scraper.rb")
    end

    it { expect(php.scraper_templates.keys.sort).to eq %w[composer.json composer.lock platform scraper.php] }

    it do
      expect(php.scraper_templates["scraper.php"]).to eq File.read("default_files/php/template/scraper.php")
    end

    it { expect(python.scraper_templates.keys.sort).to eq %w[.python-version platform requirements.txt scraper.py] }

    it do
      expect(python.scraper_templates["scraper.py"]).to eq File.read("default_files/python/template/scraper.py")
    end

    it { expect(perl.scraper_templates.keys.sort).to eq %w[cpanfile platform scraper.pl] }

    it do
      expect(perl.scraper_templates["scraper.pl"]).to eq File.read("default_files/perl/template/scraper.pl")
    end
  end
end
