# typed: strict
# frozen_string_literal: true

# A real human being (hopefully)
#
# == Schema Information
#
# Table name: owners
#
#  id                     :integer          not null, primary key
#  admin                  :boolean          default(FALSE), not null
#  alerted_at             :datetime
#  api_key                :string(255)
#  blog                   :string(255)
#  company                :string(255)
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string(255)
#  email                  :string(255)
#  feature_switches       :string(255)
#  gravatar_url           :string(255)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string(255)
#  location               :string(255)
#  name                   :string(255)
#  nickname               :string(255)
#  remember_created_at    :datetime
#  remember_token         :string(255)
#  sign_in_count          :integer          default(0), not null
#  suspended              :boolean          default(FALSE), not null
#  type                   :string(255)
#  created_at             :datetime
#  updated_at             :datetime
#  stripe_customer_id     :string(255)
#  stripe_plan_id         :string(255)
#  stripe_subscription_id :string(255)
#
# Indexes
#
#  index_owners_on_api_key   (api_key)
#  index_owners_on_nickname  (nickname) UNIQUE
#
class User < Owner
  extend T::Sig

  devise :trackable, :rememberable, :omniauthable, omniauth_providers: %i[github gitlab]
  has_many :organizations_users, dependent: :destroy
  has_many :organizations, through: :organizations_users
  has_many :alerts, dependent: :destroy
  has_many :contributions, dependent: :destroy
  has_many :scrapers_contributed_to, through: :contributions, source: :scraper

  # In most cases people have contributed to the scrapers that they own so we
  # really don't want to see these twice. This method just removes their own
  # scrapers from the list
  sig { returns(ActiveRecord::AssociationRelation) }
  def other_scrapers_contributed_to
    scrapers_contributed_to.where.not(owner: self)
  end

  # A list of all owners thst this user can write to. Includes itself
  sig { returns(T::Array[Owner]) }
  def all_owners
    [self] + organizations.to_a
  end

  # Send all alerts. This method should be run from a daily cron job
  sig { void }
  def self.process_alerts
    User.all.find_each(&:process_alerts)
  end

  sig { void }
  def process_alerts
    return if watched_broken_scrapers_ordered_by_urgency.empty?

    AlertMailer.alert_email(
      self,
      watched_broken_scrapers_ordered_by_urgency,
      watched_successful_scrapers
    ).deliver_now
  rescue Net::SMTPSyntaxError
    Rails.logger.warn "Warning: user #{nickname} has invalid email address #{email} " \
                      "(tried to send alert)"
  end

  sig { override.returns(T::Boolean) }
  def user?
    true
  end

  sig { override.returns(T::Boolean) }
  def organization?
    false
  end

  sig { params(object: T.any(Owner, Scraper)).void }
  def toggle_watch(object)
    if watching?(object)
      alerts.where(watch: object).first.destroy
    else
      # If we're starting to watch a whole bunch of scrapers (by watching a
      # user/org) and we're already following one of those scrapers individually
      # then remove the individual alert
      watch object
      if object.is_a?(Owner)
        alerts.where(watch_id: object.scrapers,
                     watch_type: "Scraper").destroy_all
      end
    end
  end

  sig { params(object: T.any(Owner, Scraper)).void }
  def watch(object)
    alerts.create(watch: object) unless watching?(object)
  end

  sig { void }
  def watch_all_owners
    all_owners.each do |object|
      watch object
    end
  end

  # Only include scrapers that finished in the last 48 hours
  sig { returns(T::Array[Scraper]) }
  def watched_successful_scrapers
    all_scrapers_watched.select do |s|
      s.finished_successfully? && s.finished_recently?
    end
  end

  sig { returns(T::Array[Scraper]) }
  def watched_broken_scrapers
    all_scrapers_watched.select do |s|
      s.finished_with_errors? && s.finished_recently?
    end
  end

  # Puts scrapers that have most recently failed first
  sig { returns(T::Array[Scraper]) }
  def watched_broken_scrapers_ordered_by_urgency
    watched_broken_scrapers.sort do |a, b|
      time_a = a.latest_successful_run_time
      time_b = b.latest_successful_run_time
      if time_b.nil? && time_a.nil?
        0
      elsif time_b.nil?
        -1
      elsif time_a.nil?
        1
      else
        T.must(time_b <=> time_a)
      end
    end
  end

  sig { returns(T::Array[Organization]) }
  def organizations_watched
    alerts.map(&:watch).select { |w| w.is_a?(Organization) }
  end

  sig { returns(T::Array[User]) }
  def users_watched
    alerts.map(&:watch).select { |w| w.is_a?(User) }
  end

  sig { returns(T::Array[Owner]) }
  def owners_watched
    alerts.map(&:watch).select { |w| w.is_a?(Owner) }
  end

  sig { returns(T::Array[Scraper]) }
  def scrapers_watched
    alerts.map(&:watch).select { |w| w.is_a?(Scraper) }
  end

  sig { returns(T::Array[Scraper]) }
  def all_scrapers_watched
    s = scrapers_watched
    owners_watched.each { |owner| s += owner.scrapers }
    s.uniq
  end

  # Are we watching this scraper because we're watching the owner
  # of the scraper?
  sig { params(scraper: Scraper).returns(T::Boolean) }
  def indirectly_watching?(scraper)
    watching?(T.must(scraper.owner))
  end

  sig { params(object: T.any(Owner, Scraper)).returns(T::Boolean) }
  def watching?(object)
    alerts.map(&:watch).include? object
  end

  # The owners (this user and their Organizations) that have an account on
  # `forge`, so a scraper there can be put under them.
  sig { params(forge: Morph::Forge::Base).returns(T::Array[Owner]) }
  def owners_on(forge)
    all_owners.select { |owner| owner.forge_identity(forge.key) }
  end

  # Refreshes which Organizations this user belongs to, from every forge they
  # have a working identity on. Membership from a forge the user cannot
  # currently reach is left as it was.
  sig { void }
  def refresh_organizations!
    refreshed = organizations.to_a
    forge_identities.select { |identity| identity.access_token.present? }.each do |identity|
      forge = identity.forge
      refreshed.reject! { |org| org.forge_identity(forge.key) }
      refreshed.concat(forge.person_client(identity).organizations.map do |profile|
        org = Organization.find_or_create_from_forge!(forge, profile)
        org.refresh_info_from_profile!(profile)
        org
      end)
    end

    # Watch any new organizations
    (refreshed - organizations.to_a).each do |o|
      watch o
    end

    self.organizations = refreshed.uniq
  end

  # Someone has just come back from a forge's OAuth flow with nobody signed in.
  # Finds them by their account on that forge or creates them, and freshens the
  # identity's login and tokens.
  sig { params(forge: Morph::Forge::Base, auth: T.untyped).returns(User) }
  def self.find_or_create_from_oauth(forge, auth)
    uid = auth.uid.to_s
    login = forge.login_from_omniauth(auth)
    user = T.cast(ForgeIdentity.owner_for(forge.key, uid), T.nilable(User))
    user ||= User.create!(nickname: Owner.available_nickname(login, forge.key))
    user.update!(nickname: Owner.available_nickname(login, forge.key, except: user))
    user.attach_forge_identity!(forge, auth)
    user.refresh_info_after_sign_in(forge, auth)
    user
  end

  # Records or freshens this user's account on a forge from an OmniAuth callback.
  sig { params(forge: Morph::Forge::Base, auth: T.untyped).returns(ForgeIdentity) }
  def attach_forge_identity!(forge, auth)
    identity = forge_identity(forge.key) || forge_identities.build(forge_key: forge.key, uid: auth.uid.to_s)
    identity.login = forge.login_from_omniauth(auth)
    identity.store_tokens!(forge.tokens_from_omniauth(auth))
    forge_identities.reset
    identity
  end

  sig { params(forge: Morph::Forge::Base, auth: T.untyped).void }
  def refresh_info_after_sign_in(forge, auth)
    # What the forge told OmniAuth is enough to be going on with; the full
    # profile and the organisations follow in the background.
    info = auth.info
    update!(name: info.name, email: info.email, gravatar_url: info.image) if forge.key == "gitlab"
    refresh_info_from_forge!(forge) if forge.key == "github"
    RefreshUserOrganizationsWorker.perform_async(T.must(id))
  end

  # Profile fields from the user's own account on `forge`. Quietly does
  # nothing if the identity's token no longer works.
  sig { params(forge: Morph::Forge::Base).returns(T::Boolean) }
  def refresh_info_from_forge!(forge)
    identity = forge_identity(forge.key)
    return false if identity.nil? || identity.access_token.blank?

    profile = forge.person_client(identity).profile
    update(name: profile.name, gravatar_url: profile.avatar_url, blog: profile.blog,
           company: profile.company, location: profile.location, email: profile.email)
  rescue Octokit::Unauthorized, Octokit::NotFound, Morph::GitlabClient::Unauthorized, Morph::GitlabClient::NotFound
    false
  end

  sig { void }
  def refresh_info_from_github!
    refresh_info_from_forge!(Morph::Forge.for("github"))
  end

  sig { returns(T::Boolean) }
  def active_for_authentication?
    !suspended?
  end

  # TODO: Move this to locale
  sig { returns(String) }
  def inactive_message
    "Your account has been suspended. " \
      "Please contact us if you think this is in error."
  end

  sig { returns(T::Boolean) }
  def never_alerted?
    alerted_at.blank?
  end

  # Note that calling this method will fail if the user's GitHub identity has no access
  # token. This will be the case if the user has not yet logged in since the switch-over
  # of the week of Oct 10 2022.
  sig { returns(Morph::Github) }
  def github
    Morph::Github.new(user_nickname: T.must(nickname), user_access_token: T.must(T.must(github_identity).access_token))
  end
end
