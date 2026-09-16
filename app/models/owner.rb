# typed: strict
# frozen_string_literal: true

# A user or organization that a scraper belongs to
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
class Owner < ApplicationRecord
  extend T::Sig
  extend T::Helpers
  abstract!

  extend FriendlyId
  friendly_id :nickname

  # nickname is the one slug behind every owner URL (ADR 0008). The database
  # index is the guarantee; this is the friendly error.
  validates :nickname, uniqueness: { case_sensitive: false }, allow_nil: true

  # Using smaller batch_size than the default for the time being because
  # reindexing causes elasticsearch on the local VM to run out of memory
  searchkick batch_size: 100 # defaults to 1000

  has_many :scrapers, inverse_of: :owner, dependent: :restrict_with_exception
  has_many :runs, dependent: :restrict_with_exception
  has_many :forge_identities, dependent: :destroy
  before_create :set_api_key
  has_many :watches, class_name: "Alert", foreign_key: :watch_id, dependent: :destroy, inverse_of: :watch
  has_many :watchers, through: :watches, source: :user

  serialize :feature_switches

  # Supporters that are on a particular plan
  scope :supporters, ->(plan) { where(stripe_plan_id: plan.stripe_plan_id) }

  scope :all_supporters, -> { where.not(stripe_plan_id: "") }

  # Specify the data searchkick should index
  sig { returns(T::Hash[String, T.nilable(String)]) }
  def search_data
    as_json only: %i[name nickname company]
  end

  sig { abstract.returns(T::Boolean) }
  def user?; end

  sig { abstract.returns(T::Boolean) }
  def organization?; end

  sig { returns(T.nilable(String)) }
  def name
    # If nickname and name are identical return nil
    return nil if self[:name] == nickname

    self[:name]
  end

  sig { returns(T.nilable(String)) }
  def blog
    b = self[:blog]
    if b.blank?
      nil
    elsif b =~ %r{https?://}
      b
    else
      "http://#{b}"
    end
  end

  sig { returns(Float) }
  def wall_time
    runs.sum(:wall_time).to_f
  end

  sig { returns(Float) }
  def utime
    scrapers.joins(:metrics).sum(:utime).to_f
  end

  sig { returns(Float) }
  def stime
    scrapers.joins(:metrics).sum(:stime).to_f
  end

  sig { returns(Float) }
  def cpu_time
    utime + stime
  end

  sig { returns(Integer) }
  def repo_size
    scrapers.sum(:repo_size)
  end

  sig { returns(Integer) }
  def sqlite_db_size
    scrapers.sum(:sqlite_db_size)
  end

  sig { returns(Integer) }
  def total_disk_usage
    repo_size + sqlite_db_size
  end

  sig { void }
  def set_api_key
    self.api_key =
      Digest::MD5.base64digest(id.to_s + rand.to_s + Time.zone.now.to_s)[0...20]
  end

  # The nickname a login on a forge gets on morph.io: the login itself unless
  # another Owner already answers to it, in which case it is suffixed with the
  # forge (ADR 0008). `except` is the Owner asking, whose own nickname is fine.
  sig { params(login: String, forge_key: String, except: T.nilable(Owner)).returns(String) }
  def self.available_nickname(login, forge_key, except: nil)
    taken = Owner.where.not(id: except&.id)
    return login unless taken.exists?(nickname: login)

    candidates = ["#{login}-#{forge_key}"] + (2..99).map { |n| "#{login}-#{forge_key}-#{n}" }
    candidates.find { |candidate| !taken.exists?(nickname: candidate) } || raise("No free nickname for #{login}")
  end

  sig { params(forge_key: String).returns(T.nilable(ForgeIdentity)) }
  def forge_identity(forge_key)
    forge_identities.find { |identity| identity.forge_key == forge_key }
  end

  sig { returns(T.nilable(ForgeIdentity)) }
  def github_identity
    forge_identity("github")
  end

  sig { returns(T.nilable(ForgeIdentity)) }
  def gitlab_identity
    forge_identity("gitlab")
  end

  # An identity cannot go if it is the last way this owner has of signing in,
  # or if any of their scrapers live on that forge.
  sig { params(identity: ForgeIdentity).returns(T.nilable(String)) }
  def reason_not_to_disconnect(identity)
    if forge_identities.size <= 1
      "It is the only account you can sign in with"
    elsif scrapers.exists?(forge_key: identity.forge_key)
      "You still have scrapers on #{identity.forge.name}"
    end
  end

  # Organizations and users store their gravatar in different ways
  # TODO: Fix this
  # TODO: Move this out of the model
  sig { params(size: Integer).returns(T.nilable(String)) }
  def gravatar_url(size = 440)
    url = self[:gravatar_url]
    return if url.nil?

    u = URI.parse(url)
    queries = (u.query || "").split("&")
    queries << "s=#{size}"
    u.query = queries.join("&")
    u.to_s
  end

  sig { returns(String) }
  def repo_root
    "db/scrapers/repos/#{to_param}"
  end

  sig { returns(String) }
  def data_root
    "db/scrapers/data/#{to_param}"
  end

  sig { returns(T::Boolean) }
  def supporter?
    stripe_plan_id.present?
  end

  sig { returns(T.nilable(Plan)) }
  def plan
    s = stripe_plan_id
    Plan.new(s) if s
  end

  # Every forge this owner is known on, each with the URL of their page there.
  sig { returns(T::Array[[Morph::Forge::Base, String]]) }
  def forge_profiles
    forge_identities.map do |identity|
      forge = Morph::Forge.for(identity.forge_key)
      [forge, forge.owner_url(self)]
    end
  end
end
