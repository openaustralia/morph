# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :user

  factory :scraper do
    sequence(:name) { |n| "my_scraper#{n}" }
    sequence(:full_name) { |n| "mlandauer/my_scraper#{n}" }
    owner factory: :user
  end

  factory :run do
    owner factory: :user
  end

  factory :organization

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
  end
end
