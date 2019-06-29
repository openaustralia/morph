require 'spec_helper'

describe Discourse::SingleSignOn do
  let(:secret) { "this is my test secret" }

  describe ".parse" do
    it "should raise an error if the signature is invalid" do
      expect { Discourse::SingleSignOn.parse("sso=abcd&sig=abcd", secret) }.to raise_error RuntimeError
    end

    it "should not raise an error if the signature is valid" do
      expect { Discourse::SingleSignOn.parse("sso=abcd&sig=cd95df15286d42d97d6268525c4e2f11d3005a4e599ce4cb0ce01d08d8a94c5a", secret) }.not_to raise_error
    end

    it "should base64 decode the sso" do
      # "bm9uY2U9aGVsbG8%3D%0A" is what you get when you base64 encode and cgi escape "nonce=hello"
      sso = Discourse::SingleSignOn.parse("sso=bm9uY2U9aGVsbG8%3D%0A&sig=51fb49b2c69a9953e7e5cf7e11661915836eb242d26fbc1f3d8638117d0dd561", secret)
      expect(sso.nonce).to eq "hello"
    end

    it "should be able to generate a url correctly encoded" do
      sso = Discourse::SingleSignOn.new
      sso.sso_secret = secret
      sso.nonce = "abcd"
      sso.email = "matthew@oaf.org.au"
      sso.name = "Matthew Landauer"
      expect(sso.to_url("https://discuss.morph.io/session/sso_login")).to eq "https://discuss.morph.io/session/sso_login?sso=bm9uY2U9YWJjZCZuYW1lPU1hdHRoZXcrTGFuZGF1ZXImZW1haWw9bWF0dGhl%0AdyU0MG9hZi5vcmcuYXU%3D%0A&sig=d710f9621b50d5f24d305718e09f7fe97a1f60201de7f589002854514af542bb"
      expect(Base64.decode64(CGI.unescape("bm9uY2U9YWJjZCZuYW1lPU1hdHRoZXcrTGFuZGF1ZXImZW1haWw9bWF0dGhl%0AdyU0MG9hZi5vcmcuYXU%3D%0A"))).to eq "nonce=abcd&name=Matthew+Landauer&email=matthew%40oaf.org.au"
    end
  end
end
