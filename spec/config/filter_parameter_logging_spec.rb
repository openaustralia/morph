# typed: false
# frozen_string_literal: true

require "spec_helper"

describe "request log filtering" do # rubocop:disable RSpec/DescribeClass
  let(:filter) { ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters) }

  it "hides a Postal webhook payload, which holds recipient addresses and server replies" do
    body = { "event" => "MessageBounced", "payload" => { "original_message" => { "to" => "someone@example.org" } } }
    filtered = filter.filter(body)

    expect(filtered.to_s).not_to include("someone@example.org")
    expect(filtered["event"]).to eq "MessageBounced"
  end

  it "leaves other parameters alone" do
    expect(filter.filter("total" => "5", "to" => "x")).to eq("total" => "5", "to" => "x")
  end
end
