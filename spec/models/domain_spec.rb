require 'spec_helper'

describe Domain do
  describe ".lookup_meta" do
    context "domain hasn't been seen before" do
      it do
        resource = double(get: "<html><head><title>\nMorph   </title><meta name='Description' content='Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud.'></head></html>")
        RestClient::Resource.should_receive(:new).with("http://morph.io", verify_ssl: OpenSSL::SSL::VERIFY_NONE).and_return(resource)
        Domain.lookup_meta("morph.io").should == "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
        Domain.count.should == 1
        domain = Domain.first
        domain.name.should == "morph.io"
        domain.meta.should == "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
        domain.title.should == "Morph"
      end
    end

    context "domain has been seen before" do
      before(:each) { Domain.create!(name: "morph.io", meta: "Foo")}

      it do
        RestClient.should_not_receive(:get)
        Domain.lookup_meta("morph.io").should == "Foo"
        Domain.count.should == 1
      end
    end
  end
end
