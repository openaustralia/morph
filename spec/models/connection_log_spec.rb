require 'spec_helper'

describe ConnectionLog do
  describe ".create" do
    before(:each) do
      Run.create(id: 18, ip_address: "10.0.1.15", started_at: Date.new(2014,1,1))
      # This is the most recent use of 10.0.1.15
      Run.create(id: 20, ip_address: "10.0.1.15", started_at: Date.new(2014,2,1))
      Run.create(id: 22, ip_address: "10.0.1.12", started_at: Date.new(2014,3,1))
    end

    it "should convert ip_address to run_id" do
      a = ConnectionLog.create(ip_address: "10.0.1.15", host: "foo.com")
      a.run_id.should == 20
    end

    it "should not convert ip_address if run_id is already set" do
      a = ConnectionLog.create(ip_address: "10.0.1.15", run_id: 40, host: "foo.com")
      a.run_id.should == 40
    end

    it "should leave the run_id empty if ip address isn't recognised" do
      a = ConnectionLog.create(ip_address: "10.0.1.23", host: "foo.com")
      a.run_id.should be_nil
    end
  end
end
