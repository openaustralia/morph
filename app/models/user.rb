# frozen_string_literal: true

# A real human being (hopefully)
class User < Owner
  devise :trackable, :rememberable, :omniauthable, omniauth_providers: [:github]
  has_many :organizations_users, dependent: :destroy
  has_many :organizations, through: :organizations_users
  has_many :alerts, dependent: :destroy
  has_many :contributions, dependent: :destroy
  has_many :scrapers_contributed_to, through: :contributions, source: :scraper

  # This feature flag doesn't do anything anymore
  # TODO: Remove it
  def see_downloads
    get_feature_switch_value(:see_downloads, false)
  end

  def see_downloads=(value)
    set_feature_switch_value(:see_downloads, value)
  end

  # In most cases people have contributed to the scrapers that they own so we
  # really don't want to see these twice. This method just removes their own
  # scrapers from the list
  def other_scrapers_contributed_to
    scrapers_contributed_to - scrapers
  end

  # A list of all owners thst this user can write to. Includes itself
  def all_owners
    [self] + organizations
  end

  def reset_authorization!
    update(
      access_token: Morph::Github.reset_authorization(access_token)
    )
  end

  # Send all alerts. This method should be run from a daily cron job
  def self.process_alerts
    User.all.find_each(&:process_alerts)
  end

  def process_alerts
    return if watched_broken_scrapers_ordered_by_urgency.empty?

    AlertMailer.alert_email(
      self,
      watched_broken_scrapers_ordered_by_urgency,
      watched_successful_scrapers
    ).deliver
  rescue Net::SMTPSyntaxError
    Rails.logger.warn "Warning: user #{nickname} has invalid email address #{email} " \
                      "(tried to send alert)"
  end

  def user?
    true
  end

  def organization?
    false
  end

  def toggle_watch(object)
    if watching?(object)
      alerts.where(watch: object).first.destroy
    else
      # If we're starting to watch a whole bunch of scrapers (by watching a
      # user/org) and we're already following one of those scrapers individually
      # then remove the individual alert
      watch object
      if object.respond_to?(:scrapers)
        alerts.where(watch_id: object.scrapers,
                     watch_type: "Scraper").destroy_all
      end
    end
  end

  def watch(object)
    alerts.create(watch: object) unless watching?(object)
  end

  def watch_all_owners
    all_owners.each do |object|
      watch object
    end
  end

  # Only include scrapers that finished in the last 48 hours
  def watched_successful_scrapers
    all_scrapers_watched.select do |s|
      s.finished_successfully? && s.finished_recently?
    end
  end

  def watched_broken_scrapers
    all_scrapers_watched.select do |s|
      s.finished_with_errors? && s.finished_recently?
    end
  end

  # Puts scrapers that have most recently failed first
  def watched_broken_scrapers_ordered_by_urgency
    watched_broken_scrapers.sort do |a, b|
      if b.latest_successful_run_time.nil? && a.latest_successful_run_time.nil?
        0
      elsif b.latest_successful_run_time.nil?
        -1
      elsif a.latest_successful_run_time.nil?
        1
      else
        b.latest_successful_run_time <=> a.latest_successful_run_time
      end
    end
  end

  def organizations_watched
    alerts.map(&:watch).select { |w| w.is_a?(Organization) }
  end

  def users_watched
    alerts.map(&:watch).select { |w| w.is_a?(User) }
  end

  def scrapers_watched
    alerts.map(&:watch).select { |w| w.is_a?(Scraper) }
  end

  def all_scrapers_watched
    s = scrapers_watched
    (organizations_watched + users_watched).each { |owner| s += owner.scrapers }
    s.uniq
  end

  # Are we watching this scraper because we're watching the owner
  # of the scraper?
  def indirectly_watching?(scraper)
    watching?(scraper.owner)
  end

  def watching?(object)
    alerts.map(&:watch).include? object
  end

  def refresh_organizations!
    refreshed_organizations = octokit_client.organizations(nickname).map do |data|
      org = Organization.find_or_create(data.id, data.login)
      org.refresh_info_from_github!(octokit_client)
      org
    end

    # Watch any new organizations
    (refreshed_organizations - organizations).each do |o|
      watch o
    end

    self.organizations = refreshed_organizations
  end

  def octokit_client
    Octokit::Client.new access_token: access_token
  end

  def self.find_for_github_oauth(auth, _signed_in_resource = nil)
    user = User.find_or_create_by(provider: auth.provider, uid: auth.uid)
    user.update(nickname: auth.info.nickname,
                access_token: auth.credentials.token)
    user.refresh_info_from_github!
    # Also every time you login it should update the list of organizations that
    # the user is attached to but do this in a background job
    RefreshUserOrganizationsWorker.perform_async(user.id)
    user
  end

  def refresh_info_from_github!
    user = octokit_client.user(nickname)
    update(name: user.name,
           gravatar_url: user._rels[:avatar].href,
           blog: user.blog,
           company: user.company,
           location: user.location,
           email: Morph::Github.primary_email(self))
  rescue Octokit::Unauthorized, Octokit::NotFound
    false
  end

  def self.find_or_create_by_nickname(nickname)
    u = User.find_by(nickname: nickname)
    if u.nil?
      u = User.create(nickname: nickname)
      u.refresh_info_from_github!
    end
    u
  end

  def users
    []
  end

  def active_for_authentication?
    !suspended?
  end

  def inactive_message
    "Your account has been suspended. " \
      "Please contact us if you think this is in error."
  end

  def never_alerted?
    alerted_at.blank?
  end
end
