# typed: strict
# frozen_string_literal: true

class OwnerAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    # You can look at your own settings
    can :settings, Owner, id: user&.id
    can :settings_redirect, Owner unless user.nil?
    can :reset_key, Owner, id: user&.id unless SiteSetting.read_only_mode

    # user should be able to see settings for an org they're part of
    if user.is_a?(User)
      user.organizations.each do |org|
        can :settings, Owner, id: org.id
        can :reset_key, Owner, id: org.id unless SiteSetting.read_only_mode
      end
    end

    # Admins can look at all owner settings
    can :settings, Owner if user&.admin?

    # Everyone can show and watch anyone
    can :show, Owner
    can :watch, Owner unless user.nil? || SiteSetting.read_only_mode
  end
end
