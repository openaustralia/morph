# typed: false
# frozen_string_literal: true

require "spec_helper"

describe AlertMailer do
  describe "#alert" do
    let(:user) { create(:user, name: "Matthew Landauer", email: "matthew@oaf.org.au", nickname: "mlandauer", alerted_at: Time.zone.now) }
    let(:full_name1) { "planningalerts-scrapers/campbelltown" }
    let(:full_name2) { "planningalerts-scrapers/spear" }
    let(:scraper1) { mock_model(Scraper, to_param: full_name1, latest_successful_run_time: 3.days.ago, full_name: full_name1) }
    let(:scraper2) { mock_model(Scraper, to_param: full_name2, latest_successful_run_time: 7.days.ago, full_name: full_name2) }
    let(:run1) do
      mock_model(Run, finished_at: 2.hours.ago, scraper: scraper1,
                      error_text: "PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16\n")
    end
    let(:run2) do
      mock_model(Run, finished_at: 22.hours.ago, scraper: scraper2,
                      error_text: "/repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )\n")
    end

    before do
      allow(scraper1).to receive(:last_run).and_return(run1)
      allow(scraper2).to receive(:last_run).and_return(run2)
    end

    context "with one broken scraper" do
      let(:broken_scrapers) { [scraper1] }
      let(:email) { described_class.alert_email(user, broken_scrapers, []) }

      it { expect(email.from).to eq ["contact@morph.io"] }
      it { expect(email.to).to eq ["matthew@oaf.org.au"] }
      it { expect(email.subject).to eq "1 scraper you are watching has errored in the last 48 hours" }

      context "when never alerted" do
        let(:user) { create(:user, name: "Matthew Landauer", email: "matthew@oaf.org.au", nickname: "mlandauer", alerted_at: nil) }
        let(:welcome_text) { "Hello and welcome to your dev.morph.io alert email." }

        it { expect(email.text_part.body.to_s).to include(welcome_text) }
        it { expect(email.html_part.body.to_s).to include(welcome_text) }
      end
    end

    context "with two broken scrapers" do
      let(:broken_scrapers) { [scraper1, scraper2] }
      let(:email) { described_class.alert_email(user, broken_scrapers, [scraper1] * 32) }

      it { expect(email.subject).to eq "2 scrapers you are watching have errored in the last 48 hours" }

      it do
        expect(email.text_part.body.to_s).to eq <<~EMAIL
          dev.morph.io is letting you know that

          32 scrapers you are watching have run successfully in the last 48 hours. These 2 have a problem:

          planningalerts-scrapers/campbelltown errored
          It has been erroring for 3 days
          Fix it: http://dev.morph.io/planningalerts-scrapers/campbelltown?utm_medium=email&utm_source=alerts

          PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16


          planningalerts-scrapers/spear errored
          It has been erroring for 7 days
          Fix it: http://dev.morph.io/planningalerts-scrapers/spear?utm_medium=email&utm_source=alerts

          /repo/scraper.rb:98:in `<main>' : undefined method `field_with' for nil:NilClass ( NoMethodError )


          -----
          Annoyed by these emails? Then change what you're watching - http://dev.morph.io/users/mlandauer/watching?utm_medium=email&utm_source=alerts
          dev.morph.io - http://dev.morph.io/?utm_medium=email&utm_source=alerts
        EMAIL
      end

      it do
        expected = <<~EMAIL
          <a href="http://dev.morph.io/?utm_medium=email&amp;utm_source=alerts">dev.morph.io</a>
          is letting you know that
        EMAIL
        expect(email.html_part.body.to_s).to include(expected)
      end

      it do
        expected = <<~EMAIL
          <h3>32 scrapers you are watching have run successfully in the last 48 hours. These 2 have a problem:</h3>
          <h3>
          <a href="http://dev.morph.io/planningalerts-scrapers/campbelltown?utm_medium=email&amp;utm_source=alerts">planningalerts-scrapers/campbelltown</a>
          errored
          </h3>
          <p>
          It has been erroring for 3 days
          </p>
          <pre>PHP Fatal error: Call to a member function find() on a non-object in /repo/scraper.php on line 16</pre>
          <h3>
          <a href="http://dev.morph.io/planningalerts-scrapers/spear?utm_medium=email&amp;utm_source=alerts">planningalerts-scrapers/spear</a>
          errored
          </h3>
          <p>
          It has been erroring for 7 days
          </p>
          <pre>/repo/scraper.rb:98:in `&lt;main&gt;&#39; : undefined method `field_with&#39; for nil:NilClass ( NoMethodError )</pre>
        EMAIL
        expect(email.html_part.body.to_s).to include(expected)
      end

      it do
        expected = <<~EMAIL
          <p>
          Annoyed by these emails? Then
          <a href="http://dev.morph.io/users/mlandauer/watching?utm_medium=email&amp;utm_source=alerts">change what you&#39;re watching</a>
          </p>
          <p><a href="http://dev.morph.io/?utm_medium=email&amp;utm_source=alerts">dev.morph.io</a></p>
        EMAIL
        expect(email.html_part.body.to_s).to include(expected)
      end
    end

    context "when more than 5 lines of errors for a scraper run" do
      it "trunctates the log output" do
        allow(run1).to receive(:error_text).and_return("This is line one of an error\nThis is line two\nLine three\nLine four\nLine five\nLine six\n")
        expect(described_class.alert_email(user, [scraper1], [scraper1] * 32).text_part.body.to_s).to eq <<~EMAIL
          dev.morph.io is letting you know that

          32 scrapers you are watching have run successfully in the last 48 hours. This 1 has a problem:

          planningalerts-scrapers/campbelltown errored
          It has been erroring for 3 days
          Fix it: http://dev.morph.io/planningalerts-scrapers/campbelltown?utm_medium=email&utm_source=alerts

          This is line one of an error
          This is line two
          Line three
          Line four
          Line five
          (truncated)


          -----
          Annoyed by these emails? Then change what you're watching - http://dev.morph.io/users/mlandauer/watching?utm_medium=email&utm_source=alerts
          dev.morph.io - http://dev.morph.io/?utm_medium=email&utm_source=alerts
        EMAIL
      end
    end

    describe "count of number of scrapers that finished successfully" do
      context "with 32 scrapers" do
        let(:mail) { described_class.alert_email(user, [scraper1], [scraper1] * 32) }

        it { expect(mail.text_part.body.to_s).to include("32 scrapers you are watching have run successfully in the last 48 hours. This 1 has a problem:") }
        it { expect(mail.html_part.body.to_s).to include("32 scrapers you are watching have run successfully in the last 48 hours. This 1 has a problem:") }
      end

      context "with 1 scraper" do
        let(:mail) { described_class.alert_email(user, [scraper1], [scraper1]) }

        it { expect(mail.text_part.body.to_s).to include("1 scraper you are watching has run successfully in the last 48 hours. This 1 has a problem:") }
        it { expect(mail.html_part.body.to_s).to include("1 scraper you are watching has run successfully in the last 48 hours. This 1 has a problem:") }
      end
    end
  end
end
