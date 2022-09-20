# typed: strict
# frozen_string_literal: true

class ScraperAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(owner: T.nilable(Owner)).void }
  def initialize(owner)
    # Everyone can list all (non private) scrapers
    can :read, Scraper, private: false

    return unless owner

    can :data, Scraper, private: false
    can :create, Scraper unless SiteSetting.read_only_mode
    can :watch, Scraper, private: false unless SiteSetting.read_only_mode

    # user can view scrapers owned by them (even if private) and settings of scrapers they own
    can %i[read data], Scraper, owner_id: owner.id
    can %i[destroy update watch], Scraper, owner_id: owner.id unless SiteSetting.read_only_mode

    # user can view scrapers and settings of scrapers belonging to an org they are a
    # member of
    if owner.is_a?(User)
      owner.organizations.each do |org|
        can %i[read data], Scraper, owner_id: org.id
        can %i[destroy update create watch], Scraper, owner_id: org.id unless SiteSetting.read_only_mode
      end
    end

    return unless owner.admin?

    # Admins also have the special power to update the memory setting and increase the memory available to the scraper
    can :memory_setting, Scraper
  end
end
