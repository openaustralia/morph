class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new # guest user (not logged in)
    # user can view settings of scrapers it owns
    can [:settings, :destroy, :update, :run, :stop, :clear, :create, :create_github], Scraper, owner_id: user.id

    # user can view settings of scrapers belonging to an org they are a member of
    user.organizations.each do |org|
      can [:settings, :destroy, :update, :run, :stop, :clear, :create, :create_github], Scraper, owner_id: org.id
    end

    # Everyone can list all the scrapers
    can [:index, :show, :watchers, :new], Scraper

    # You can look at your own settings
    can :settings, Owner, id: user.id
    # user should be able to see settings for an org they're part of
    user.organizations.each do |org|
      can :settings, Owner, id: org.id
    end
    # Admins can look at all owner settings
    if user.admin?
      can :settings, Owner
    end
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
