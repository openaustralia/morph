# typed: strict
# frozen_string_literal: true

class SiteSettingAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    # No powers given to anonymous users here
    return unless user

    # No powers given to logged in ("normal") users here
    return unless user.admin?

    can :toggle_read_only_mode, SiteSetting
    can :update_maximum_concurrent_scrapers, SiteSetting
  end
end
