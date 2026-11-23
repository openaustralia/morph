# typed: false
# frozen_string_literal: true

require "spec_helper"

describe "config/initializers/searchkick.rb" do
  let(:initializer) { Rails.root.join("config/initializers/searchkick.rb") }
  let(:vendor_json) { "application/vnd.elasticsearch+json; compatible-with=7" }

  around do |example|
    original_options = Searchkick.client_options
    original_env = ENV.fetch("ELASTIC_CLIENT_APIVERSIONING", nil)
    example.run
  ensure
    Searchkick.client_options = original_options
    ENV["ELASTIC_CLIENT_APIVERSIONING"] = original_env
  end

  %w[true 1].each do |value|
    it "sends the vendor Content-Type when API versioning is #{value}" do
      ENV["ELASTIC_CLIENT_APIVERSIONING"] = value
      Searchkick.client_options = {}
      load initializer
      expect(Searchkick.client_options.dig(:transport_options, :headers, :content_type)).to eq vendor_json
    end
  end

  [nil, "false", "test"].each do |value|
    it "leaves Searchkick's Content-Type alone when API versioning is #{value.inspect}" do
      ENV["ELASTIC_CLIENT_APIVERSIONING"] = value
      Searchkick.client_options = {}
      load initializer
      expect(Searchkick.client_options).to eq({})
    end
  end
end
