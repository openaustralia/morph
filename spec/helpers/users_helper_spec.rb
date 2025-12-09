# typed: false
# frozen_string_literal: true

require "spec_helper"

describe UsersHelper do
  describe "alert_scrapers_summary_sentence" do
    it "generates correct sentence for single success and failure" do
      expect(helper.alert_scrapers_summary_sentence(1, 1)).to include("1 scraper", "has run", "This 1 has a problem")
    end

    it "generates correct sentence for multiple" do
      expect(helper.alert_scrapers_summary_sentence(3, 2)).to include("3 scrapers", "have run", "These 2 have a problem")
    end
  end
end
