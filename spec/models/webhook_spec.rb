require 'spec_helper'

RSpec.describe Webhook, type: :model do
  it "should require a url" do
    webhook = Webhook.new
    expect(webhook).to_not be_valid
    expect(webhook.errors.keys).to eq([:url])
  end
end
