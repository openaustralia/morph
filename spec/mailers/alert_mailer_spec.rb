require "spec_helper"

describe AlertMailer do
  describe "#alert" do
    let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au") }

    context "one broken scraper" do
      let(:broken_scrapers) { [mock_model(Scraper)] }
      let(:email) { AlertMailer.alert_email(user, broken_scrapers) }

      it { email.from.should == ["contact@morph.io"]}
      it { email.to.should == ["matthew@oaf.org.au"]}
      it { email.subject.should == "Morph: 1 scraper you are watching is erroring" }
      it do
        email.body.to_s.should == <<-EOF
Scrapers have failed
        EOF
      end
    end

    context "two broken scrapers" do
      let(:broken_scrapers) { [mock_model(Scraper), mock_model(Scraper)] }
      let(:email) { AlertMailer.alert_email(user, broken_scrapers) }

      it { email.subject.should == "Morph: 2 scrapers you are watching are erroring" }
    end
  end  
end
