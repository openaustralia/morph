require 'spec_helper'

describe SupportersHelper do
  describe "#plan_change_word" do
    context "no current plan" do
      it { expect(helper.plan_change_word(nil, "basic")).to eql "Signup" }
      it { expect(helper.plan_change_word("", "basic")).to eql "Signup" }
      it { expect(helper.plan_change_word(" ", "basic")).to eql "Signup" }
    end

    context "plan upgrade" do
      it { expect(helper.plan_change_word("basic", "standard")).to eql "Upgrade" }
      it { expect(helper.plan_change_word("basic", "advanced")).to eql "Upgrade" }
      it { expect(helper.plan_change_word("standard", "advanced")).to eql "Upgrade" }
    end

    context "plan downgrade" do
      it { expect(helper.plan_change_word("standard", "basic")).to eql "Downgrade" }
      it { expect(helper.plan_change_word("advanced", "basic")).to eql "Downgrade" }
      it { expect(helper.plan_change_word("advanced", "standard")).to eql "Downgrade" }
    end
  end
end
