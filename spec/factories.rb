# typed: false
# frozen_string_literal: true

FactoryBot.define do
  factory :owner
  factory :user

  factory :scraper do
    name { "my_scraper" }
    full_name { "mlandauer/my_scraper" }
    owner
  end

  factory :run do
    owner
  end

  factory :organization
end
