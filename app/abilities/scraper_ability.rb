# typed: strict
# frozen_string_literal: true

class ScraperAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(User)).void }
  def initialize(user)
    # Everyone can list all (non private) scrapers
    can %i[index show watchers running history], Scraper, private: false

    return unless user

    can :data, Scraper, private: false
    can %i[new github github_form], Scraper unless SiteSetting.read_only_mode
    can :watch, Scraper, private: false unless SiteSetting.read_only_mode

    # user can view scrapers owned by them (even if private) and settings of scrapers they own
    can %i[index show watchers running history settings data], Scraper, owner_id: user.id

    unless SiteSetting.read_only_mode
      can %i[destroy update run stop clear create create_github watch],
          Scraper,
          owner_id: user.id
    end

    # user can view scrapers and settings of scrapers belonging to an org they are a
    # member of
    user.organizations.each do |org|
      can %i[index show watchers running history settings data], Scraper, owner_id: org.id
      next if SiteSetting.read_only_mode

      can %i[destroy update run stop clear create create_github watch],
          Scraper,
          owner_id: org.id
    end

    return unless user.admin?

    # Admins also have the special power to update the memory setting and increase the memory available to the scraper
    can :memory_setting, Scraper
  end
end
