# typed: strict
# frozen_string_literal: true

class OwnerAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(User)).void }
  def initialize(user)
    # Everyone can show and watch anyone
    can :show, Owner

    return unless user

    # You can look at your own settings
    can :settings, Owner, id: user.id
    can :settings_redirect, Owner
    can :reset_key, Owner, id: user.id unless SiteSetting.read_only_mode
    # Can watch any owner of repos
    can :watch, Owner unless SiteSetting.read_only_mode

    # user should be able to see settings for an org they're part of
    user.organizations.each do |org|
      can :settings, Owner, id: org.id
      can :reset_key, Owner, id: org.id unless SiteSetting.read_only_mode
    end

    return unless user.admin?

    # Admins can look at all owner settings
    can :settings, Owner
  end
end
