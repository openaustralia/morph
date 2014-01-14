require 'spec_helper'

describe CodeTranslate do
  describe ".ruby" do
    it "should do a series of translations and return the final result" do
      input = double
      output = double
      CodeTranslate.should_receive(:add_require).with(input).and_return(output)
      CodeTranslate.ruby(input).should == output
    end
  end

  describe ".add_require" do
    it "should replace scraperwiki with scraperwiki-morph (with single quotes)" do
      CodeTranslate.add_require("require 'scraperwiki'\nsome other code\n").should ==
        "require 'scraperwiki-morph'\nsome other code\n"
    end

    it "should replace scraperwiki with scraperwiki-morph (with double quotes)" do
      CodeTranslate.add_require("require \"scraperwiki\"\nsome other code\n").should ==
        "require 'scraperwiki-morph'\nsome other code\n"
    end

    it "should add the require if it's not there" do
      CodeTranslate.add_require("some code\n").should ==
        "require 'scraperwiki-morph'\nsome code\n"
    end
  end
end
