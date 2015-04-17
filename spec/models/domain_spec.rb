require 'spec_helper'

describe Domain do
  describe ".lookup_meta" do
    context "domain hasn't been seen before" do
      it do
        RestClient.should_receive(:get).with("http://morph.io").and_return("<html><head><meta name='Description' content='Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud.'></head></html>")
        Domain.lookup_meta("morph.io").should == "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
        Domain.count.should == 1
        domain = Domain.first
        domain.name.should == "morph.io"
        domain.meta.should == "Get structured data out of the web. Code collaboration through GitHub. Run your scrapers in the cloud."
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
