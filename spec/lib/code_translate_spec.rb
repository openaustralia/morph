require 'spec_helper'

describe CodeTranslate do
  describe ".ruby" do
    it "should do a series of translations and return the final result" do
      input, output1, output2 = double, double, double
      CodeTranslate.should_receive(:add_require).with(input).and_return(output1)
      CodeTranslate.should_receive(:switch_to_scraperwiki_morph).with(output1).and_return(output2)
      CodeTranslate.ruby(input).should == output2
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

  describe ".switch_to_scraperwiki_morph" do
    it "should replace all uses of ScraperWiki with ScraperWikiMorph" do
      CodeTranslate.switch_to_scraperwiki_morph("if foo\n  ScraperWiki.select(twiddle, bob)\nend\n").should ==
        "if foo\n  ScraperWikiMorph.select(twiddle, bob)\nend\n"
    end
  end
end
