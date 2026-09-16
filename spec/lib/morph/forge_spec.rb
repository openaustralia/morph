# typed: false
# frozen_string_literal: true

require "spec_helper"

describe Morph::Forge do
  describe ".for" do
    it "returns the GitHub adapter for 'github'" do
      expect(described_class.for("github")).to be_a(Morph::Forge::Github)
    end

    it "raises on a forge morph.io does not know" do
      expect { described_class.for("sourcehut") }.to raise_error(ArgumentError, /sourcehut/)
    end
  end

  describe ".all" do
    it "lists every forge, GitHub first" do
      expect(described_class.all.map(&:key)).to start_with("github")
    end
  end
end
