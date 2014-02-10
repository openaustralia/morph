class User < Owner
  # TODO Add :omniauthable
  devise :trackable, :omniauthable, :omniauth_providers => [:github]
  has_and_belongs_to_many :organizations, join_table: :organizations_users
  has_many :alerts

  # Send all alerts. This method should be run from a daily cron job
  def self.process_alerts
    User.all.each do |user|
      user.process_alerts
    end
  end

  def process_alerts
    broken_scrapers = all_scrapers_watched.select do |s|
      s.last_run && s.last_run.auto? && s.last_run.finished_with_errors?
    end
    successful_scrapers = all_scrapers_watched.select do |s|
      s.last_run && s.last_run.auto? && s.last_run.finished_successfully?
    end

    broken_runs = broken_scrapers.map{|s| s.last_run}
    successful_count = successful_scrapers.count

    unless broken_runs.empty?
      AlertMailer.alert_email(self, broken_runs, successful_count).deliver
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
    self.organizations = octokit_client.organizations.map {|data| Organization.find_or_create(data.id, data.login) }
  end

  def octokit_client
    Octokit::Client.new :access_token => access_token
  end

  def self.find_for_github_oauth(auth, signed_in_resource=nil)
    user = User.find_or_create_by(:provider => auth.provider, :uid => auth.uid)
    user.update_attributes(nickname: auth.info.nickname, name:auth.info.name,
      access_token: auth.credentials.token,
      gravatar_id: auth.extra.raw_info.gravatar_id,
      blog: auth.extra.raw_info.blog,
      company: auth.extra.raw_info.company, email:auth.info.email)
    # Also every time you login it should update the list of organizations that the user is attached to
    user.refresh_organizations!
    user
  end

  def refresh_info_from_github!
    user = Octokit.user(nickname)
    update_attributes(name:user.name,
        # image: auth.info.image,
        gravatar_id: user.gravatar_id,
        blog: user.blog,
        company: user.company,
        email: user.email)
  end

  def users
    []
  end
end
