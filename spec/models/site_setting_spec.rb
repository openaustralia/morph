require 'spec_helper'

describe SiteSetting do
  describe ".read_only_mode" do
    it "should be false by default" do
      expect(SiteSetting.read_only_mode).to eq false
    end

    it "should persist a setting" do
      SiteSetting.read_only_mode = true
      expect(SiteSetting.read_only_mode).to eq true
    end
  end

  describe ".toggle_read_only_mode!" do
    it "should toggle false to true" do
      SiteSetting.read_only_mode = false
      SiteSetting.toggle_read_only_mode!
      expect(SiteSetting.read_only_mode).to eq true
    end

    it "should toggle true to false" do
      SiteSetting.read_only_mode = true
      SiteSetting.toggle_read_only_mode!
      expect(SiteSetting.read_only_mode).to eq false
    end
  end
end
