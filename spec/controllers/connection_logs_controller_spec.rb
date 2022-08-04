# typed: false
# frozen_string_literal: true

require "spec_helper"

describe ConnectionLogsController do
  describe "#create" do
    before { allow(described_class).to receive(:key).and_return("sjdf") }

    it "is successful if correct key is used" do
      allow(UpdateDomainWorker).to receive(:perform_async)
      post :create, params: { key: "sjdf", host: "foo.com" }
      expect(response).to be_successful
      expect(UpdateDomainWorker).to have_received(:perform_async)
    end

    it "is not successful if wrong key is used" do
      post :create, params: { key: "foo" }
      expect(response).not_to be_successful
    end
  end
end
