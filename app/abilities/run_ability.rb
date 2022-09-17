# typed: strict
# frozen_string_literal: true

class RunAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    # Nothing given to anonymous users
    return unless user

    can :create, Run unless SiteSetting.read_only_mode
  end
end
