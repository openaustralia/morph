require 'spec_helper'

describe SiteSetting do
  describe ".read_only_mode" do
    it "should be false by default" do
      SiteSetting.read_only_mode.should == false
    end

    it "should persist a setting" do
      SiteSetting.read_only_mode = true
      SiteSetting.read_only_mode.should == true
    end
  end
end
