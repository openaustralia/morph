# typed: strict
# frozen_string_literal: true

class Ability
  extend T::Sig

  include CanCan::Ability

  sig { params(_user: T.nilable(User)).void }
  # rubocop:disable Style/RedundantInitialize
  def initialize(_user); end
  # rubocop:enable Style/RedundantInitialize
end
