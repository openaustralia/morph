# typed: strict
# frozen_string_literal: true

class UserAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(_user: T.nilable(Owner)).void }
  def initialize(_user)
    # Everybody can look at all the users and see who they are watching
    can %i[index watching], User
    can :stats, User
  end
end
