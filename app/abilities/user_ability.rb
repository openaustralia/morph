# typed: strict
# frozen_string_literal: true

class UserAbility < Ability
  extend T::Sig

  include CanCan::Ability

  sig { params(_user: T.nilable(User)).void }
  def initialize(_user)
    super
    # Everybody can look at all the users and see who they are watching
    can %i[index watching], User
    can :stats, User
  end
end
