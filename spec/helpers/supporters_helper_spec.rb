# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SupportersHelper do
  describe "#plan_change_word" do
    let(:basic) { Plan.new("morph_basic") }
    let(:standard) { Plan.new("morph_standard") }
    let(:advanced) { Plan.new("morph_advanced") }

    context "with no current plan" do
      # TODO: Refactor or remove?
      context "when morph_basic" do
        it { expect(helper.plan_change_word(Plan.new(nil), basic)).to eql "Become a #{basic.name}" }
        it { expect(helper.plan_change_word(Plan.new(""), basic)).to eql "Become a #{basic.name}" }
        it { expect(helper.plan_change_word(Plan.new(" "), basic)).to eql "Become a #{basic.name}" }
      end

      context "when morph_standard" do
        it { expect(helper.plan_change_word(Plan.new(nil), standard)).to eql "Become a #{standard.name}" }
        it { expect(helper.plan_change_word(Plan.new(""), standard)).to eql "Become a #{standard.name}" }
        it { expect(helper.plan_change_word(Plan.new(" "), standard)).to eql "Become a #{standard.name}" }
      end

      context "when morph_advanced" do
        it { expect(helper.plan_change_word(Plan.new(nil), advanced)).to eql "Become a #{advanced.name}" }
        it { expect(helper.plan_change_word(Plan.new(""), advanced)).to eql "Become a #{advanced.name}" }
        it { expect(helper.plan_change_word(Plan.new(" "), advanced)).to eql "Become a #{advanced.name}" }
      end
    end

    context "when upgrading plan" do
      it { expect(helper.plan_change_word(basic, standard)).to eql "Upgrade" }
      it { expect(helper.plan_change_word(basic, advanced)).to eql "Upgrade" }
      it { expect(helper.plan_change_word(standard, advanced)).to eql "Upgrade" }
    end

    context "when downgrading plan" do
      it { expect(helper.plan_change_word(standard, basic)).to eql "Downgrade" }
      it { expect(helper.plan_change_word(advanced, basic)).to eql "Downgrade" }
      it { expect(helper.plan_change_word(advanced, standard)).to eql "Downgrade" }
    end
  end
end
