require 'spec_helper'

describe NewDomainWorker do
  let(:worker) { NewDomainWorker.new }
  describe "#perform" do
    context "domain hasn't been seen before" do
      it do
        RestClient.should_receive(:get).with("http://morph.io").and_return("<html><head><meta name='Description' content='Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud.'></head></html>")
        worker.perform("morph.io")
        Domain.count.should == 1
        domain = Domain.first
        domain.name.should == "morph.io"
        domain.meta.should == "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
      end
    end
  end
end
