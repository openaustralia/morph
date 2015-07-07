require 'spec_helper'

describe SupportersHelper do
  describe "#plan_change_word" do
    context "no current plan" do
      it { expect(helper.plan_change_word(nil, "morph_basic")).to eql "Signup" }
      it { expect(helper.plan_change_word("", "morph_basic")).to eql "Signup" }
      it { expect(helper.plan_change_word(" ", "morph_basic")).to eql "Signup" }
    end

    context "plan upgrade" do
      it { expect(helper.plan_change_word("morph_basic", "morph_standard")).to eql "Upgrade" }
      it { expect(helper.plan_change_word("morph_basic", "morph_advanced")).to eql "Upgrade" }
      it { expect(helper.plan_change_word("morph_standard", "morph_advanced")).to eql "Upgrade" }
    end

    context "plan downgrade" do
      it { expect(helper.plan_change_word("morph_standard", "morph_basic")).to eql "Downgrade" }
      it { expect(helper.plan_change_word("morph_advanced", "morph_basic")).to eql "Downgrade" }
      it { expect(helper.plan_change_word("morph_advanced", "morph_standard")).to eql "Downgrade" }
    end
  end
end
