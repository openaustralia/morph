# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ApplicationHelper do
  describe "#sanitize_highlight" do
    it "passes through plain text unchanged" do
      expect(helper.sanitize_highlight("foo")).to eq "foo"
    end

    it "passes through text with emphasis unchanged" do
      expect(helper.sanitize_highlight("this is a <em>search result</em>")).to eq "this is a <em>search result</em>"
    end

    it "removes other html" do
      expect(helper.sanitize_highlight("<b>this</b> is a <em>search result</em>")).to eq "this is a <em>search result</em>"
    end

    it "returns text that is html safe" do
      expect(helper.sanitize_highlight("foo")).to be_html_safe
    end
  end
end