require 'spec_helper'

describe Domain do
  describe "#update_meta!" do
    it do
      resource = double(get: "<html><head><title>\nMorph   </title><meta name='Description' content='Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud.'></head></html>")
      RestClient::Resource.should_receive(:new).with("http://morph.io", verify_ssl: OpenSSL::SSL::VERIFY_NONE).and_return(resource)

      domain = Domain.create!(name: "morph.io")
      domain.update_meta!
      domain.reload
      domain.name.should == "morph.io"
      domain.meta.should == "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
      domain.title.should == "Morph"
    end
  end
end
