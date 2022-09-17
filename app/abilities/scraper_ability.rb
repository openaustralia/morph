# typed: strict
# frozen_string_literal: true

class ScraperAbility
  extend T::Sig

  include CanCan::Ability

  sig { params(user: T.nilable(Owner)).void }
  def initialize(user)
    # user can view settings of scrapers it owns
    can :settings, Scraper, owner_id: user&.id
    if user&.admin?
      # Admins also have the special power to update the memory setting and increase the memory available to the scraper
      can :memory_setting, Scraper
    end
    # TODO: Don't like the use of persisted? here. Refactor.
    unless user.nil? || SiteSetting.read_only_mode
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
    can %i[new github github_form watch], Scraper unless user.nil? || SiteSetting.read_only_mode
  end
end
