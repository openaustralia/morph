# typed: false
# frozen_string_literal: true

require "spec_helper"

describe SupportersHelper do
  let(:basic) { Plan.new("morph_basic") }
  let(:standard) { Plan.new("morph_standard") }
  let(:advanced) { Plan.new("morph_advanced") }

  describe "#plan_change_word" do
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
      it("from basic to standard") { expect(helper.plan_change_word(basic, standard)).to eql "Upgrade" }
      it("from basic to advanced") { expect(helper.plan_change_word(basic, advanced)).to eql "Upgrade" }
      it("from standard top advanced") { expect(helper.plan_change_word(standard, advanced)).to eql "Upgrade" }
    end

    context "when downgrading plan" do
      it("from standard to basic") { expect(helper.plan_change_word(standard, basic)).to eql "Downgrade" }
      it("from advanced to basic") { expect(helper.plan_change_word(advanced, basic)).to eql "Downgrade" }
      it("from advanced to standard") { expect(helper.plan_change_word(advanced, standard)).to eql "Downgrade" }
    end
  end

  describe "#plan_change_word_past_tense" do
    it("from basic to standard") { expect(helper.plan_change_word_past_tense(basic, standard)).to eql "Upgraded" }
    it("from basic to advanced") { expect(helper.plan_change_word_past_tense(basic, advanced)).to eql "Upgraded" }
    it("from standard to advanced") { expect(helper.plan_change_word_past_tense(standard, advanced)).to eql "Upgraded" }
    it("from standard to basic") { expect(helper.plan_change_word_past_tense(standard, basic)).to eql "Downgraded" }
    it("from advanced to basic") { expect(helper.plan_change_word_past_tense(advanced, basic)).to eql "Downgraded" }
    it("from advanced to standard") { expect(helper.plan_change_word_past_tense(advanced, standard)).to eql "Downgraded" }
    it("from standard to standard") { expect { helper.plan_change_word_past_tense(standard, standard) }.to raise_error RuntimeError }
  end

  describe "#joy_or_disappointment" do
    it("from basic to standard") { expect(helper.joy_or_disappointment(basic, standard)).to eql "You're amazing!" }
    it("from basic to advanced") { expect(helper.joy_or_disappointment(basic, advanced)).to eql "You're amazing!" }
    it { expect(helper.joy_or_disappointment(standard, advanced)).to eql "You're amazing!" }
    it { expect(helper.joy_or_disappointment(standard, basic)).to eql "Thanks for continuing to be a supporter!" }
    it { expect(helper.joy_or_disappointment(advanced, basic)).to eql "Thanks for continuing to be a supporter!" }
    it { expect(helper.joy_or_disappointment(advanced, standard)).to eql "Thanks for continuing to be a supporter!" }
    it { expect { helper.joy_or_disappointment(standard, standard) }.to raise_error RuntimeError }
  end

  describe "#plan_reason" do
    it("for basic plan") { expect(helper.plan_reason(basic)).to eql "Support morph.io on a budget. Keep morph.io open and running and available to all" }
    it("for standard plan") { expect(helper.plan_reason(standard)).to eql "Support continued development of the open-source software that powers morph.io" }
    it("for advanced plan") { expect(helper.plan_reason(advanced)).to eql "Rely on morph.io for your business or not-for-profit? Priority technical support to get you answers and fixes quickly" }
  end

  describe "#plan_recognition" do
    it("for basic plan") { expect(helper.plan_recognition(basic)).to eql "<strong>Shows</strong> your support publicly" }
    it("for standard plan") { expect(helper.plan_recognition(standard)).to eql "<strong>Be featured</strong> on the landing page" }
    it("for advanced plan") { expect(helper.plan_recognition(advanced)).to eql "<strong>Be featured</strong> on the landing page" }
  end

  describe "#plan_support" do
    it("for basic plan") { expect(helper.plan_support(basic)).to eql "<strong>Forum</strong> support" }
    it("for standard plan") { expect(helper.plan_support(standard)).to eql "<strong>Forum</strong> support" }
    it("for advanced plan") { expect(helper.plan_support(advanced)).to eql "<strong>Priority</strong> technical support" }
  end
end
