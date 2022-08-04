# typed: false
# frozen_string_literal: true

# Who has permission to do what
class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # user can view settings of scrapers it owns
    can :settings, Scraper, owner_id: user.id
    if user.admin?
      # Admins also have the special power to update the memory setting and increase the memory available to the scraper
      can :memory_setting, Scraper
    end
    unless SiteSetting.read_only_mode
      can %i[destroy update run stop clear create create_github],
          Scraper,
          owner_id: user.id
    end

    # user can view settings of scrapers belonging to an org they are a
    # member of
    user.organizations.each do |org|
      can :settings, Scraper, owner_id: org.id
      next if SiteSetting.read_only_mode

      can %i[destroy update run stop clear create create_github],
          Scraper,
          owner_id: org.id
    end

    # Everyone can list all the scrapers
    can %i[index show watchers], Scraper
    can %i[new github], Scraper unless SiteSetting.read_only_mode

    # You can look at your own settings
    can :settings, Owner, id: user.id
    can :reset_key, Owner, id: user.id unless SiteSetting.read_only_mode

    # user should be able to see settings for an org they're part of
    user.organizations.each do |org|
      can :settings, Owner, id: org.id
      can :reset_key, Owner, id: org.id unless SiteSetting.read_only_mode
    end

    # Admins can look at all owner settings and update
    if user.admin?
      can :settings, Owner
      can :update, Owner unless SiteSetting.read_only_mode
    end

    # Everyone can show and watch anyone
    can :show, Owner
    can :watch, Owner unless SiteSetting.read_only_mode

    # Everybody can look at all the users and see who they are watching
    can %i[index watching], User
    can :stats, User
    can :toggle_read_only_mode, SiteSetting if user.admin?
    can :update_sidekiq_maximum_concurrent_scrapers, SiteSetting if user.admin?

    can :create, Run unless SiteSetting.read_only_mode
    # Define abilities for the passed in user here. For example:
    #
    #   user ||= User.new # guest user (not logged in)
    #   if user.admin?
    #     can :manage, :all
    #   else
    #     can :read, :all
    #   end
    #
    # The first argument to `can` is the action you are giving the user
    # permission to do.
    # If you pass :manage it will apply to every action. Other common actions
    # here are :read, :create, :update and :destroy.
    #
    # The second argument is the resource the user can perform the action on.
    # If you pass :all it will apply to every resource. Otherwise pass a Ruby
    # class of the resource.
    #
    # The third argument is an optional hash of conditions to further filter the
    # objects.
    # For example, here the user can only update published articles.
    #
    #   can :update, Article, :published => true
    #
    # See the wiki for details:
    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
