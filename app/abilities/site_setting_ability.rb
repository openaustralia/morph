# typed: strict
# frozen_string_literal: true

class SiteSettingAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    can :toggle_read_only_mode, SiteSetting if user&.admin?
    can :update_maximum_concurrent_scrapers, SiteSetting if user&.admin?
  end
end
