require 'spec_helper'

describe SupportersHelper do
  describe "#plan_change_word" do
    context "no current plan" do
      it { expect(helper.plan_change_word(Plan.new(nil), Plan.new("morph_basic"))).to eql "Signup" }
      it { expect(helper.plan_change_word(Plan.new(""), Plan.new("morph_basic"))).to eql "Signup" }
      it { expect(helper.plan_change_word(Plan.new(" "), Plan.new("morph_basic"))).to eql "Signup" }
    end

    context "plan upgrade" do
      it { expect(helper.plan_change_word(Plan.new("morph_basic"), Plan.new("morph_standard"))).to eql "Upgrade" }
      it { expect(helper.plan_change_word(Plan.new("morph_basic"), Plan.new("morph_advanced"))).to eql "Upgrade" }
      it { expect(helper.plan_change_word(Plan.new("morph_standard"), Plan.new("morph_advanced"))).to eql "Upgrade" }
    end

    context "plan downgrade" do
      it { expect(helper.plan_change_word(Plan.new("morph_standard"), Plan.new("morph_basic"))).to eql "Downgrade" }
      it { expect(helper.plan_change_word(Plan.new("morph_advanced"), Plan.new("morph_basic"))).to eql "Downgrade" }
      it { expect(helper.plan_change_word(Plan.new("morph_advanced"), Plan.new("morph_standard"))).to eql "Downgrade" }
    end
  end
end
