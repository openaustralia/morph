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
    end

    context "two broken scrapers" do
      let(:broken_scrapers) { [mock_model(Scraper), mock_model(Scraper)] }
      let(:email) { AlertMailer.alert_email(user, broken_scrapers) }

      it { email.subject.should == "Morph: 2 scrapers you are watching are erroring" }
      it do
        email.body.to_s.should == <<-EOF
planningalerts-scrapers/campbelltown errored about 2 hours ago
Fix it: https://morph.io/planningalerts-scrapers/campbelltown
PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16

planningalerts-scrapers/spear errored about 22 hours ago
Fix it: https://morph.io/planningalerts-scrapers/spear
/repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )

32 other scrapers you are watching ran without error

-----
Change what you're watching - https://morph.io/users/mlandauer/watching
Morph.io - https://morph.io
        EOF
      end
    end
  end  
end
