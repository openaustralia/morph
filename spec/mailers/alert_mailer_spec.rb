require "spec_helper"

describe AlertMailer do
  describe "#alert" do
    let(:full_name1) { "planningalerts-scrapers/campbelltown" }
    let(:full_name2) { "planningalerts-scrapers/spear" }
    let(:scraper1) { mock_model(Scraper, to_param: full_name1, latest_successful_run_time: 3.days.ago) }
    let(:scraper2) { mock_model(Scraper, to_param: full_name2, latest_successful_run_time: 7.days.ago) }
    let(:run1) { mock_model(Run, full_name: full_name1, finished_at: 2.hours.ago, scraper: scraper1,
      error_text: "PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16\n") }
    let(:run2) { mock_model(Run, full_name: full_name2, finished_at: 22.hours.ago, scraper: scraper2,
      error_text: "/repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )\n") }

    context "one broken scraper" do
      let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au", to_param: "mlandauer", broken_runs: [run1], successful_runs: []) }
      let(:email) { AlertMailer.alert_email(user) }

      it { email.from.should == ["contact@morph.io"]}
      it { email.to.should == ["matthew@oaf.org.au"]}
      it { email.subject.should == "morph.io: 1 scraper you are watching is erroring" }
    end

    context "two broken scrapers" do
      let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au", to_param: "mlandauer", broken_runs: [run1, run2], successful_runs: 32.times.collect { mock_model(Run) }) }
      let(:email) { AlertMailer.alert_email(user) }

      it { email.subject.should == "morph.io: 2 scrapers you are watching are erroring" }
      it do
        email.text_part.body.to_s.should == <<-EOF
morph.io is letting you know that


planningalerts-scrapers/spear errored
It has been erroring for 7 days
Fix it: http://dev.morph.io/planningalerts-scrapers/spear?utm_medium=email&utm_source=alerts

/repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )


planningalerts-scrapers/campbelltown errored
It has been erroring for 3 days
Fix it: http://dev.morph.io/planningalerts-scrapers/campbelltown?utm_medium=email&utm_source=alerts

PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16


32 other scrapers you are watching finished successfully

-----
Annoyed by these emails? Then change what you're watching - http://dev.morph.io/users/mlandauer/watching?utm_medium=email&utm_source=alerts
morph.io - http://dev.morph.io/?utm_medium=email&utm_source=alerts
        EOF
      end

      it do
        expected = <<-EOF
<a href="http://dev.morph.io/?utm_medium=email&amp;utm_source=alerts">morph.io</a>
is letting you know that
        EOF
        email.html_part.body.to_s.should include(expected)
      end

      it do
        expected = <<-EOF
<h3>
<a href="http://dev.morph.io/planningalerts-scrapers/spear?utm_medium=email&amp;utm_source=alerts">planningalerts-scrapers/spear</a>
errored
</h3>
<p>
It has been erroring for 7 days
</p>
<pre>/repo/scraper.rb:98:in `&lt;main&gt;' : undefined method `field_with' for nil:NilClass ( NoMethodError )</pre>
<h3>
<a href="http://dev.morph.io/planningalerts-scrapers/campbelltown?utm_medium=email&amp;utm_source=alerts">planningalerts-scrapers/campbelltown</a>
errored
</h3>
<p>
It has been erroring for 3 days
</p>
<pre>PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16</pre>
<h3>32 other scrapers you are watching finished successfully</h3>
        EOF
        email.html_part.body.to_s.should include(expected)
      end

      it do
        expected = <<-EOF
<p>
Annoyed by these emails? Then
<a href="http://dev.morph.io/users/mlandauer/watching?utm_medium=email&amp;utm_source=alerts">change what you&#39;re watching</a>
</p>
<p><a href="http://dev.morph.io/?utm_medium=email&amp;utm_source=alerts">morph.io</a></p>
        EOF
        email.html_part.body.to_s.should include(expected)
      end
    end

    context "more than 5 lines of errors for a scraper run" do
      let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au", to_param: "mlandauer", broken_runs: [run1], successful_runs: 32.times.collect { mock_model(Run) }) }
      it "should trunctate the log output" do
        run1.stub(error_text: "This is line one of an error\nThis is line two\nLine three\nLine four\nLine five\nLine six\n")
        AlertMailer.alert_email(user).text_part.body.to_s.should == <<-EOF
morph.io is letting you know that


planningalerts-scrapers/campbelltown errored
It has been erroring for 3 days
Fix it: http://dev.morph.io/planningalerts-scrapers/campbelltown?utm_medium=email&utm_source=alerts

This is line one of an error
This is line two
Line three
Line four
Line five
(truncated)


32 other scrapers you are watching finished successfully

-----
Annoyed by these emails? Then change what you're watching - http://dev.morph.io/users/mlandauer/watching?utm_medium=email&utm_source=alerts
morph.io - http://dev.morph.io/?utm_medium=email&utm_source=alerts
        EOF
      end
    end

    describe "count of number of scrapers that finished successfully" do
      context "32 scrapers" do
        let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au", to_param: "mlandauer", broken_runs: [run1], successful_runs: 32.times.collect { mock_model(Run) }) }
        let(:mail) { AlertMailer.alert_email(user) }
        it { mail.text_part.body.to_s.should include("32 other scrapers you are watching finished successfully") }
        it { mail.html_part.body.to_s.should include("32 other scrapers you are watching finished successfully") }
      end

      context "1 scraper" do
        let(:user) { mock_model(User, name: "Matthew Landauer", email: "matthew@oaf.org.au", to_param: "mlandauer", broken_runs: [run1], successful_runs: [mock_model(Run)]) }
        let(:mail) { AlertMailer.alert_email(user) }
        it { mail.text_part.body.to_s.should include("1 other scraper you are watching finished successfully") }
        it { mail.html_part.body.to_s.should include("1 other scraper you are watching finished successfully") }
      end
    end
  end  
end
