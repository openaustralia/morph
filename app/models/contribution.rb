# frozen_string_literal: true

# Contribution of a user to the code a scraper
class Contribution < ActiveRecord::Base
  belongs_to :user
  belongs_to :scraper
end
