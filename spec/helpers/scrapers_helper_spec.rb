require 'spec_helper'

describe ScrapersHelper do
  describe "#is_url?" do
    it { expect(helper.is_url?("foobar")).to eq false }
    it { expect(helper.is_url?("http://example.com blah")).to eq false }
    it { expect(helper.is_url?("ftp://example.com/no_ftp")).to eq false }
    it { expect(helper.is_url?('<a href="http://example.com">blah</a>')).to eq false }
    it { expect(helper.is_url?("http://example.com")).to eq true }
    it { expect(helper.is_url?("http://example.com/#anchor")).to eq true }
  end
end
