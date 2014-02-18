require 'spec_helper'

describe Morph::Language do
  describe ".human" do
    it { Morph::Language.human(:ruby).should == "Ruby" }
    it { Morph::Language.human(:python).should == "Python" }
    it { Morph::Language.human(:php).should == "PHP" }
  end
end
