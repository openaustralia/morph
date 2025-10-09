# typed: strict
# frozen_string_literal: true

class Ability
  extend T::Sig

  include CanCan::Ability

  sig { params(_user: T.nilable(Owner)).void }
  def initialize(_user); end # rubocop:disable Style/RedundantInitialize
end
