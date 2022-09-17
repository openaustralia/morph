# typed: strict
# frozen_string_literal: true

# Who has permission to do what
class Ability
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    # Everybody can look at all the users and see who they are watching
    can %i[index watching], User
    can :stats, User
    can :toggle_read_only_mode, SiteSetting if user&.admin?
    can :update_maximum_concurrent_scrapers, SiteSetting if user&.admin?

    can :create, Run unless user.nil? || SiteSetting.read_only_mode
  end
end
