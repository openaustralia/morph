# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    # Required in practice if you collaborate or own a scraper - only 6 users in Prod dont have nicknames
    sequence(:nickname) { |n| "user#{n}" }
    trait :maximal do
      sequence(:nickname) { |n| FactoryHelpers.max_name("full-user#{n}", 127) }
      sequence(:email) { |n| "full-user#{n}@example.com" }
      name { FactoryHelpers.max_string("User name", 255) }
      provider { "github" }
      sequence(:uid) { |n| "github_#{n}" }
      blog { FactoryHelpers.max_string("https://example.com/blog", 255) }
      company { FactoryHelpers.max_string("Acme Corporation", 255) }
      location { FactoryHelpers.max_string("Sydney, Australia", 255) }
      gravatar_url { FactoryHelpers.max_name("https://gravatar.com/avatar/test", 255) }
      admin { true }
      suspended { false }
      feature_switches { FactoryHelpers.max_serialized("featureN", 255) }
      # api_key is set by Owner model
      stripe_customer_id { FactoryHelpers.max_string("cus_test123", 255) }
      stripe_plan_id { FactoryHelpers.max_string("plan_test", 255) }
      stripe_subscription_id { FactoryHelpers.max_string("sub_test123", 255) }
      sign_in_count { 42 }
      current_sign_in_at { 1.day.ago }
      last_sign_in_at { 2.days.ago }
      current_sign_in_ip { "203.0.113.42" }
      last_sign_in_ip { "203.0.113.41" }
    end
  end

  factory :scraper do
    sequence(:name) { |n| "my_scraper#{n}" }
    owner { association(:user) }
    full_name { "#{owner.nickname}/#{name}" }

    trait :maximal do
      sequence(:name) { |n| FactoryHelpers.max_name("my_max_scraper#{n}", 127) }
      description { FactoryHelpers.max_string("Comprehensive scraper description", 255) }
      sequence(:github_id) { |n| 1000000 + n }
      sequence(:github_url) { |n| FactoryHelpers.max_string("https://github.com/owner/scraper#{n}", 255) }
      sequence(:git_url) { |n| FactoryHelpers.max_string("git@github.com:owner/scraper#{n}.git", 255) }
      auto_run { true }
      scraperwiki_url { FactoryHelpers.max_string("https://classic.scraperwiki.com/scrapers/test", 255) }
      original_language_key { FactoryHelpers.max_string("ruby", 255) }
      repo_size { 5242880 }
      sqlite_db_size { 10485760 }
      memory_mb { 512 }
    end
  end

  factory :run do
    owner factory: :user
    scraper

    trait :maximal do
      owner { association(:user, :maximal) }
      scraper { association(:scraper, :maximal) }
      started_at { 10.minutes.ago }
      finished_at { 5.minutes.ago }
      # wall_time set by finished_at
      status_code { 0 }
      queued_at { 15.minutes.ago }
      auto { true }
      git_revision { FactoryHelpers.max_string("abc123def456", 255) }
      tables_added { 5 }
      tables_removed { 2 }
      tables_changed { 3 }
      tables_unchanged { 10 }
      records_added { 1000 }
      records_removed { 50 }
      records_changed { 200 }
      records_unchanged { 5000 }
      ip_address { "203.0.113.42" }
      connection_logs_count { 25 }
      docker_image { FactoryHelpers.max_string("morph/ruby:latest", 255) }
    end
  end

  factory :metric do
    run factory: :run

    trait :maximal do
      wall_time { 45.67 }
      utime { 1.23 }
      stime { 0.54 }
      maxrss { 18765 }
      minflt { 34567 }
      majflt { 65 }
      inblock { 45678 }
      oublock { 8765 }
      nvcsw { 3210 }
      nivcsw { 345 }
    end
  end

  factory :organization do
    trait :maximal do
      sequence(:nickname) { |n| FactoryHelpers.max_name("max-org#{n}", 127) }
      sequence(:email) { |n| "max-org#{n}@example.com" }
      name { FactoryHelpers.max_string("Organization Name", 255) }
      provider { "github" }
      sequence(:uid) { |n| "github_org_#{n}" }
      company { FactoryHelpers.max_string("Big Company Inc", 255) }
      blog { FactoryHelpers.max_name("https://example.com/blog", 255) }
      location { FactoryHelpers.max_string("Melbourne, Australia", 255) }
      sign_in_count { 42 }
      current_sign_in_at { 1.day.ago }
      last_sign_in_at { 2.days.ago }
    end
  end

  factory :organizations_user do
    user
    organization
  end

  factory :collaboration do
    owner factory: :user
    scraper
    admin { false }
    maintain { false }
    pull { false }
    push { false }
    triage { false }

    trait :maximal do
      owner { association(:user, :maximal) }
      scraper { association(:scraper, :maximal) }
      admin { true }
      maintain { true }
      pull { true }
      push { true }
      triage { true }
    end
  end

  factory :alert do
    user
    watch { association(:user) }

    trait :maximal do
      user { association(:user, :maximal) }
      watch { association(:scraper, :maximal) }
    end
  end

  factory :api_query do
    scraper
    owner factory: :user
    type { "ApiQuery" }

    trait :maximal do
      scraper { association(:scraper, :maximal) }
      owner { association(:user, :maximal) }
      query { FactoryHelpers.max_string("SELECT * FROM data", 255) }
      format { FactoryHelpers.max_string("json", 255) }
      utime { 0.5 }
      stime { 0.2 }
      wall_time { 1.5 }
      size { 524288 }
    end
  end

  factory :contribution do
    scraper
    user

    trait :maximal do
      scraper { association(:scraper, :maximal) }
      user { association(:user, :maximal) }
    end
  end

  # TODO: create_scraper_progresses           726

  factory :log_line do
    run
    stream { "stdout" }
    text { "log output" }

    trait :maximal do
      run { association(:run, :maximal) }
      stream { FactoryHelpers.max_string("stderr", 255) }
      text { FactoryHelpers.max_string("Log line text", 65535) }
      timestamp { 5.minutes.ago }
    end
  end

  # TODO: site_settings                         1

  factory :variable do
    scraper
    sequence(:name) { |n| "MORPH_VAR_#{n}" }
    value { "value" }

    trait :maximal do
      scraper { association(:scraper, :maximal) }
      sequence(:name) { |n| FactoryHelpers.max_name("MORPH_VAR_#{n}", 255).gsub("-", "_") }
      value { FactoryHelpers.max_string("variable value", 65535) }
    end
  end

  factory :webhook_delivery do
    webhook
    run

    trait :maximal do
      webhook { association(:webhook, :maximal) }
      run { association(:run, :maximal) }
      sent_at { 5.minutes.ago }
      response_code { 200 }
    end
  end

  factory :webhook do
    scraper
    sequence(:url) { |n| "https://example.com/hook#{n}" }

    trait :maximal do
      scraper { association(:scraper, :maximal) }
      url { FactoryHelpers.max_name("https://example.com/webhook", 255) }
    end
  end

  # An active scraper with runs and queries
  factory :active_scraper, parent: :scraper do
    sequence(:name) { |n| "my_active_scraper#{n}" }
    owner { association(:user, nickname: "active_owner") }
    full_name { "#{owner.nickname}/#{name}" }

    after(:create) do |scraper|
      FactoryBot.create(:run, owner: scraper.owner, scraper: scraper)
      # FactoryBot.create(:api_query, owner: scraper.owner, scraper: scraper)
    end

    trait :maximal do
      name { FactoryHelpers.max_name("Active_scraper", 127) }
      # full_name { FactoryHelpers.max_string("active_owner/active_scraper", 255) }
      owner { association(:user, :maximal) }
      full_name { "#{owner.nickname}/#{name}" }
      description { FactoryHelpers.max_string("Active scraper description", 255) }
      # Don't set github_id as it causes validation to github to fail!
      # sequence(:github_id) { |n| 1000000 + n }
      github_url { FactoryHelpers.max_name("https://github.com/active/scraper", 255) }
      git_url { FactoryHelpers.max_name("git@github.com:active/scraper.git", 255) }
      auto_run { true }
      scraperwiki_url { FactoryHelpers.max_name("https://classic.scraperwiki.com/scrapers/active", 255) }
      original_language_key { FactoryHelpers.max_string("ruby", 255) }
      repo_size { 5242880 }
      sqlite_db_size { 10485760 }
      memory_mb { 512 }

      after(:create) do |scraper|
        # Create runs (including last_run)
        _run1 = FactoryBot.create(:run, :maximal, owner: scraper.owner, scraper: scraper, queued_at: 2.hours.ago)
        run2 = FactoryBot.create(:run, :maximal, owner: scraper.owner, scraper: scraper, queued_at: 1.hour.ago)

        # Create other associations
        FactoryBot.create(:api_query, :maximal, owner: scraper.owner, scraper: scraper)
        FactoryBot.create(:variable, :maximal, scraper: scraper)
        FactoryBot.create(:contribution, :maximal, scraper: scraper)
        FactoryBot.create(:collaboration, :maximal, scraper: scraper)
        FactoryBot.create(:alert, :maximal, watch: scraper)

        # Create webhook with delivery
        webhook = FactoryBot.create(:webhook, :maximal, scraper: scraper)
        FactoryBot.create(:webhook_delivery, :maximal, webhook: webhook, run: run2)
      end
    end
  end

  factory :create_scraper_progress do
    message { "Creating scraper" }
    progress { 50 }

    trait :maximal do
      heading { FactoryHelpers.max_string("New scraper", 255) }
      message { FactoryHelpers.max_string("Add scraper template", 255) }
      progress { 40 }
    end
  end
end
