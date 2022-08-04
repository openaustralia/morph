# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ConnectionLog do
  let(:user) { create(:user) }

  describe ".create" do
    before do
      Run.create!(id: 18, owner: user, ip_address: "10.0.1.15", started_at: Date.new(2014, 1, 1))
      # This is the most recent use of 10.0.1.15
      Run.create!(id: 20, owner: user, ip_address: "10.0.1.15", started_at: Date.new(2014, 2, 1))
      Run.create!(id: 22, owner: user, ip_address: "10.0.1.12", started_at: Date.new(2014, 3, 1))
      Run.create!(id: 40, owner: user, ip_address: "10.0.1.20", started_at: Date.new(2014, 3, 1))
    end

    let(:domain) { Domain.create!(name: "foo.com") }

    it "converts ip_address to run_id" do
      a = described_class.create!(ip_address: "10.0.1.15", domain: domain)
      expect(a.run_id).to eq 20
    end

    it "does not convert ip_address if run_id is already set" do
      a = described_class.create!(ip_address: "10.0.1.20", run_id: 40, domain: domain)
      expect(a.run_id).to eq 40
    end

    it "leaves the run_id empty if ip address isn't recognised" do
      a = described_class.create!(ip_address: "10.0.1.23", domain: domain)
      expect(a.run_id).to be_nil
    end
  end
end
