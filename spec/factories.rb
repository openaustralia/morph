# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :user

  factory :scraper do
    name { "my_scraper" }
    full_name { "mlandauer/my_scraper" }
    owner factory: :user
  end

  factory :run do
    owner factory: :user
  end

  factory :organization
end
