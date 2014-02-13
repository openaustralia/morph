require "spec_helper"

describe AlertMailer do
  describe "#alert" do
    let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au", to_param: "mlandauer") }
    let(:full_name1) { "planningalerts-scrapers/campbelltown" }
    let(:full_name2) { "planningalerts-scrapers/spear" }
    let(:scraper1) { mock_model(Scraper, to_param: full_name1) }
    let(:scraper2) { mock_model(Scraper, to_param: full_name2) }
    let(:run1) { mock_model(Run, full_name: full_name1, finished_at: 2.hours.ago, scraper: scraper1,
      error_text: "PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16\n") }
    let(:run2) { mock_model(Run, full_name: full_name2, finished_at: 22.hours.ago, scraper: scraper2,
      error_text: "/repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )\n") }

    context "one broken scraper" do
      let(:broken_runs) { [run1] }
      let(:email) { AlertMailer.alert_email(user, broken_runs, 32) }

      it { email.from.should == ["contact@morph.io"]}
      it { email.to.should == ["matthew@oaf.org.au"]}
      it { email.subject.should == "Morph: 1 scraper you are watching is erroring" }
    end

    context "two broken scrapers" do
      let(:broken_runs) { [run1, run2] }
      let(:email) { AlertMailer.alert_email(user, broken_runs, 32) }

      it { email.subject.should == "Morph: 2 scrapers you are watching are erroring" }
      it do
        email.text_part.body.to_s.should == <<-EOF
Morph is letting you know that


planningalerts-scrapers/campbelltown errored about 2 hours ago
Fix it: http://dev.morph.io/planningalerts-scrapers/campbelltown

PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16


planningalerts-scrapers/spear errored about 22 hours ago
Fix it: http://dev.morph.io/planningalerts-scrapers/spear

/repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )


32 other scrapers you are watching finished successfully

-----
Annoyed by these emails? Then change what you're watching - http://dev.morph.io/users/mlandauer/watching
Morph.io - http://dev.morph.io/
        EOF
      end

      it do
        expected = <<-EOF
<a href="http://dev.morph.io/">Morph</a>
is letting you know that
        EOF
        email.html_part.body.to_s.should include(expected)
      end

      it do
        expected = <<-EOF
<h3>
<a href="http://dev.morph.io/planningalerts-scrapers/campbelltown">planningalerts-scrapers/campbelltown</a>
errored about 2 hours ago
</h3>
<pre>PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16</pre>
<h3>
<a href="http://dev.morph.io/planningalerts-scrapers/spear">planningalerts-scrapers/spear</a>
errored about 22 hours ago
</h3>
<pre>/repo/scraper.rb:98:in `&lt;main&gt;' : undefined method `field_with' for nil:NilClass ( NoMethodError )</pre>
<h3>32 other scrapers you are watching finished successfully</h3>
        EOF
        email.html_part.body.to_s.should include(expected)
      end

      it do
        expected = <<-EOF
<p>
Annoyed by these emails? Then
<a href="http://dev.morph.io/users/mlandauer/watching">change what you&#39;re watching</a>
</p>
<p><a href="http://dev.morph.io/">Morph.io</a></p>
        EOF
        email.html_part.body.to_s.should include(expected)
      end
    end

    context "more than 5 lines of errors for a scraper run" do
      it "should trunctate the log output" do
        run1.stub(error_text: "This is line one of an error\nThis is line two\nLine three\nLine four\nLine five\nLine six\n")
        AlertMailer.alert_email(user, [run1], 32).text_part.body.to_s.should == <<-EOF
Morph is letting you know that


planningalerts-scrapers/campbelltown errored about 2 hours ago
Fix it: http://dev.morph.io/planningalerts-scrapers/campbelltown

This is line one of an error
This is line two
Line three
Line four
Line five
(truncated)


32 other scrapers you are watching finished successfully

-----
Annoyed by these emails? Then change what you're watching - http://dev.morph.io/users/mlandauer/watching
Morph.io - http://dev.morph.io/
        EOF
      end
    end

    describe "count of number of scrapers that finished successfully" do
      context "32 scrapers" do
        let(:mail) { AlertMailer.alert_email(user, [run1], 32) }
        it { mail.text_part.body.to_s.should include("32 other scrapers you are watching finished successfully") }
        it { mail.html_part.body.to_s.should include("32 other scrapers you are watching finished successfully") }
      end

      context "1 scraper" do
        let(:mail) { AlertMailer.alert_email(user, [run1], 1) }
        it { mail.text_part.body.to_s.should include("1 other scraper you are watching finished successfully") }
        it { mail.html_part.body.to_s.should include("1 other scraper you are watching finished successfully") }
      end
    end
  end  
end
