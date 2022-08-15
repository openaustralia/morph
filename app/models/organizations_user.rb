# typed: strict
# frozen_string_literal: true

class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user
end
