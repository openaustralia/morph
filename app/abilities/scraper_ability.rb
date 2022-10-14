# typed: strict
# frozen_string_literal: true

class ScraperAbility < Ability
  extend T::Sig

  include CanCan::Ability

  # This models which scrapers can be accessed and what can be done. We're generally
  # trying to follow what Github does so that there are the least surprises for users.
  #
  # With just public scrapers everyone can view them but you have to be either the
  # owner of the scraper or a member of an organization which owns the scraper to be
  # able to modify and run the scraper. This isn't what Github does exactly but has
  # been close enough not to cause too much confusion.
  #
  # With private scrapers it becomes much more important to more faithfully follow
  # the complex model that Github uses.
  #
  # For compatibility (in the short term) we are going to maintain the current
  # model for public scrapers but use a new more fine-grained approach for
  # private scrapers.
  #
  # TODO: Move over to using the same fine-grained approach for everyone

  sig { params(owner: T.nilable(Owner)).void }
  def initialize(owner)
    super
    # Everyone can list all (non private) scrapers
    can :read, Scraper, private: false

    return unless owner

    can :data, Scraper, private: false
    unless SiteSetting.read_only_mode
      can :create, Scraper
      can :watch, Scraper, private: false
    end

    # user can view scrapers owned by them (even if private) and settings of scrapers they own
    can_control_scrapers_owned_by(owner)

    # user can view scrapers and settings of scrapers belonging to an org they are a
    # member of
    owner.organizations.each { |org| can_control_scrapers_owned_by(org) } if owner.is_a?(User)

    return unless owner.admin?

    # Admins also have the special power to update the memory setting and increase the memory available to the scraper
    # They can also create private scrapers
    can %i[memory_setting create_private], Scraper unless SiteSetting.read_only_mode
  end

  private

  sig { params(owner: Owner).void }
  def can_control_scrapers_owned_by(owner)
    can %i[read data], Scraper, owner_id: owner.id
    can %i[destroy update watch], Scraper, owner_id: owner.id unless SiteSetting.read_only_mode
  end
end
