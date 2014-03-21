FactoryGirl.define do
  factory :owner
  factory :user

  factory :scraper do
    name 'my_scraper'
    owner
  end

  factory :organization
end
