# typed: strict
# frozen_string_literal: true

# Who has permission to do what
class Ability
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # user can view settings of scrapers it owns
    can :settings, Scraper, owner_id: user.id
    if user.admin?
      # Admins also have the special power to update the memory setting and increase the memory available to the scraper
      can :memory_setting, Scraper
    end
    # TODO: Don't like the use of persisted? here. Refactor.
    unless !user.persisted? || SiteSetting.read_only_mode
      can %i[destroy update run stop clear create create_github],
          Scraper,
          owner_id: user.id
    end

    # user can view settings of scrapers belonging to an org they are a
    # member of
    if user.is_a?(User)
      user.organizations.each do |org|
        can :settings, Scraper, owner_id: org.id
        next if SiteSetting.read_only_mode

        can %i[destroy update run stop clear create create_github],
            Scraper,
            owner_id: org.id
      end
    end

    # Everyone can list all the scrapers
    can %i[index show watchers running history], Scraper
    # TODO: Don't like the use of persisted? here. Refactor.
    can %i[new github github_form watch], Scraper unless !user.persisted? || SiteSetting.read_only_mode

    # You can look at your own settings
    can :settings, Owner, id: user.id
    can :settings_redirect, Owner if user.persisted?
    can :reset_key, Owner, id: user.id unless SiteSetting.read_only_mode

    # user should be able to see settings for an org they're part of
    if user.is_a?(User)
      user.organizations.each do |org|
        can :settings, Owner, id: org.id
        can :reset_key, Owner, id: org.id unless SiteSetting.read_only_mode
      end
    end

    # Admins can look at all owner settings
    can :settings, Owner if user.admin?

    # Everyone can show and watch anyone
    can :show, Owner
    # TODO: Don't like the use of persisted? here. Refactor.
    can :watch, Owner unless !user.persisted? || SiteSetting.read_only_mode

    # Everybody can look at all the users and see who they are watching
    can %i[index watching], User
    can :stats, User
    can :toggle_read_only_mode, SiteSetting if user.admin?
    can :update_maximum_concurrent_scrapers, SiteSetting if user.admin?

    can :create, Run unless !user.persisted? || SiteSetting.read_only_mode
  end
end
