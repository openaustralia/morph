# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: organizations_users
#
#  id              :integer          not null, primary key
#  organization_id :integer
#  user_id         :integer
#
# Indexes
#
#  index_organizations_users_on_organization_id  (organization_id)
#  index_organizations_users_on_user_id          (user_id)
#
class OrganizationsUser < ApplicationRecord
  belongs_to :organization
  belongs_to :user
end
