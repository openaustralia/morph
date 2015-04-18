require 'spec_helper'

describe ConnectionLogsController do
  describe "#create" do
    before(:each) { ConnectionLogsController.stub(key: "sjdf")}

    it "should be successful if correct key is used" do
      NewDomainWorker.should_receive(:perform_async)
      post :create, key: "sjdf"
      response.should be_successful
    end

    it "should not be successful if wrong key is used" do
      post :create, key: "foo"
      response.should_not be_successful
    end
  end
end
