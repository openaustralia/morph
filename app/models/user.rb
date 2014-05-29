class User < Owner
  # TODO Add :omniauthable
  devise :trackable, :omniauthable, :omniauth_providers => [:github]
  has_and_belongs_to_many :organizations, join_table: :organizations_users
  has_many :alerts
  has_many :contributions
  has_many :scrapers_contributed_to, through: :contributions, source: :scraper

  def buildpacks
    feature_switches[:buildpacks] if feature_switches.respond_to?(:has_key?)
  end

  def buildpacks=(value)
    s = feature_switches || {}
    s[:buildpacks] = value
    self.feature_switches = s
  end

  # In most cases people have contributed to the scrapers that they own so we really don't
  # want to see these twice. This method just removes their own scrapers from the list
  def other_scrapers_contributed_to
    scrapers_contributed_to - scrapers
  end

  # A list of all owners thst this user can write to. Includes itself
  def all_owners
    [self] + organizations
  end

  def reset_authorization!
    update_attributes(access_token: Morph::Github.reset_authorization(access_token))
  end

  # Send all alerts. This method should be run from a daily cron job
  def self.process_alerts
    User.all.each do |user|
      user.process_alerts
    end
  end

  def process_alerts
    auto_runs = all_scrapers_watched.select do |s|
      s.last_run
    end.map{|s| s.last_run}

    broken_runs = auto_runs.select {|r| r.finished_with_errors?}
    successful_runs = auto_runs.select {|r| r.finished_successfully?}

    unless broken_runs.empty?
      begin
        AlertMailer.alert_email(self, broken_runs, successful_runs.count).deliver
      rescue Net::SMTPSyntaxError
        puts "Warning: user #{nickname} has invalid email address #{email} (tried to send alert)"
      end
    end
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
      # If we're starting to watch a whole bunch of scrapers (by watching a user/org) and we're
      # already following one of those scrapers individually then remove the individual alert
      alerts.create(watch: object)
      if object.respond_to?(:scrapers)
        alerts.where(watch_id: object.scrapers, watch_type: "Scraper").destroy_all
      end
    end
  end

  def organizations_watched
    alerts.map{|a| a.watch}.select{|w| w.kind_of?(Organization)}
  end

  def users_watched
    alerts.map{|a| a.watch}.select{|w| w.kind_of?(User)}
  end

  def scrapers_watched
    alerts.map{|a| a.watch}.select{|w| w.kind_of?(Scraper)}
  end

  def all_scrapers_watched
    s = scrapers_watched
    (organizations_watched + users_watched).each {|owner| s += owner.scrapers }
    s.uniq
  end

  # Are we watching this scraper because we're watching the owner of the scraper?
  def indirectly_watching?(scraper)
    watching?(scraper.owner)
  end

  def watching?(object)
    alerts.map{|a| a.watch}.include? object
  end

  def refresh_organizations!
    self.organizations = octokit_client.organizations.map {|data| Organization.find_or_create(data.id, data.login, octokit_client) }
  end

  def octokit_client
    Octokit::Client.new :access_token => access_token
  end

  def self.find_for_github_oauth(auth, signed_in_resource=nil)
    user = User.find_or_create_by(:provider => auth.provider, :uid => auth.uid)
    user.update_attributes(nickname: auth.info.nickname,
      access_token: auth.credentials.token)
    user.refresh_info_from_github!
    # Also every time you login it should update the list of organizations that the user is attached to
    user.refresh_organizations!
    user
  end

  def refresh_info_from_github!
    user = octokit_client.user(nickname)
    update_attributes(name:user.name,
        gravatar_url: user._rels[:avatar].href,
        blog: user.blog,
        company: user.company,
        email: Morph::Github.primary_email(self))
  end

  def self.find_or_create_by_nickname(nickname)
    u = User.find_by_nickname(nickname)
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
    'Your account has been suspended. Please contact us if you think this is in error.'
  end
end
