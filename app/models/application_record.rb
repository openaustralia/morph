# typed: strict
# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  extend T::Sig

  self.abstract_class = true

  # Ransack 4 (pulled in by ActiveAdmin 3) requires every model searched
  # through it to allowlist its searchable attributes and associations.
  # Ransack is only reachable through ActiveAdmin here, which OnlyAdmins
  # restricts to admin users, so restore the pre-Ransack-4 behaviour of
  # allowing everything rather than maintaining per-model lists.
  sig { params(_auth_object: T.untyped).returns(T::Array[String]) }
  def self.ransackable_attributes(_auth_object = nil)
    authorizable_ransackable_attributes
  end

  sig { params(_auth_object: T.untyped).returns(T::Array[String]) }
  def self.ransackable_associations(_auth_object = nil)
    authorizable_ransackable_associations
  end
end
