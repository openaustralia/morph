require 'spec_helper'

describe RunsHelper do
  describe "#scraped_domains_list" do
    let(:run) { mock_model(Run) }

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com"])
      expect(helper.scraped_domains_list(run)).to eq '<a href="http://foo.com">foo.com</a>'
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com"])
      expect(helper.scraped_domains_list(run)).to eq '<a href="http://foo.com">foo.com</a> and <a href="http://bar.com">bar.com</a>'
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com", "www.foo.com"])
      expect(helper.scraped_domains_list(run)).to eq '<a href="http://foo.com">foo.com</a>, <a href="http://bar.com">bar.com</a>, and <a href="http://www.foo.com">www.foo.com</a>'
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com", "www.foo.com", "www.bar.com"])
      expect(helper.scraped_domains_list(run)).to eq '<a href="http://foo.com">foo.com</a>, <a href="http://bar.com">bar.com</a>, <a href="http://www.foo.com">www.foo.com</a>, and 1 other'
    end

    it do
      expect(run).to receive(:scraped_domains).and_return(["foo.com", "bar.com", "www.foo.com", "www.bar.com", "fiddle.com"])
      expect(helper.scraped_domains_list(run)).to eq '<a href="http://foo.com">foo.com</a>, <a href="http://bar.com">bar.com</a>, <a href="http://www.foo.com">www.foo.com</a>, and 2 other'
    end
  end
end
