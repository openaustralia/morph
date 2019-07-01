# frozen_string_literal: true

require "spec_helper"

describe ConnectionLogsController do
  describe "#create" do
    before(:each) { allow(ConnectionLogsController).to receive(:key).and_return("sjdf") }

    it "should be successful if correct key is used" do
      expect(UpdateDomainWorker).to receive(:perform_async)
      post :create, key: "sjdf", host: "foo.com"
      expect(response).to be_successful
    end

    it "should not be successful if wrong key is used" do
      post :create, key: "foo"
      expect(response).to_not be_successful
    end
  end
end
