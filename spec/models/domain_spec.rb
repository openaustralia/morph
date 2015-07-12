require 'spec_helper'

describe Domain do
  describe "#update_meta!" do
    it do
      resource = double(get: "<html><head><title>\nmorph.io   </title><meta name='Description' content='Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud.'></head></html>")
      expect(RestClient::Resource).to receive(:new).with("http://morph.io", verify_ssl: OpenSSL::SSL::VERIFY_NONE).and_return(resource)

      domain = Domain.create!(name: "morph.io")
      domain.update_meta!
      domain.reload
      expect(domain.name).to eq "morph.io"
      expect(domain.meta).to eq "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
      expect(domain.title).to eq "morph.io"
    end
  end
end
