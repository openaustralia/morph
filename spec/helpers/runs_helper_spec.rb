require 'spec_helper'

describe RunsHelper do
  describe "#scraped_domains_list" do
    let(:run) { mock_model(Run) }

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com"])
      expect(helper.scraped_domains_list(run)).to eq "foo.com"
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com"])
      expect(helper.scraped_domains_list(run)).to eq "foo.com and bar.com"
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com", "www.foo.com"])
      expect(helper.scraped_domains_list(run)).to eq "foo.com, bar.com, and www.foo.com"
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com", "www.foo.com", "www.bar.com"])
      expect(helper.scraped_domains_list(run)).to eq "foo.com, bar.com, www.foo.com, and 1 other"
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com", "www.foo.com", "www.bar.com", "fiddle.com"])
      expect(helper.scraped_domains_list(run)).to eq "foo.com, bar.com, www.foo.com, and 2 other"
    end
  end
end
