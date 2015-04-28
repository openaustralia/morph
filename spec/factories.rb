FactoryGirl.define do
  factory :owner
  factory :user

  factory :scraper do
    name 'my_scraper'
    owner
    github_id 1234

    factory :scraper_with_runs do
      transient do
        runs_count 5
      end

      after(:create) do |scraper, evaluator|
        create_list(:run, evaluator.runs_count, scraper: scraper)
      end
    end
  end

  factory :run do
    scraper
  end

  factory :organization
end
