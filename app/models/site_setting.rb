# typed: strict
# frozen_string_literal: true

# Settings that apply to the whole app and everybody on it
class SiteSetting < ApplicationRecord
  extend T::Sig
  serialize :settings

  sig { returns(T::Boolean) }
  def self.read_only_mode
    read_setting("read_only_mode")
  end

  sig { params(mode: T::Boolean).void }
  def self.read_only_mode=(mode)
    write_setting("read_only_mode", mode)
  end

  sig { void }
  def self.toggle_read_only_mode!
    self.read_only_mode = !read_only_mode
  end

  sig { returns(Integer) }
  def self.maximum_concurrent_scrapers
    read_setting("maximum_concurrent_scrapers").to_i
  end

  sig { params(number: Integer).void }
  def self.maximum_concurrent_scrapers=(number)
    write_setting("maximum_concurrent_scrapers", number)
    update_sidekiq_maximum_concurrent_scrapers!
  end

  sig { void }
  def self.update_sidekiq_maximum_concurrent_scrapers!
    Sidekiq::Queue["scraper"].limit = maximum_concurrent_scrapers
  end

  sig { returns(SiteSetting) }
  def self.record
    SiteSetting.first || SiteSetting.create(settings: defaults)
  end

  sig { params(key: String).returns(T.untyped) }
  def self.read_setting(key)
    record.settings[key] || defaults[key]
  end

  sig { params(key: String, value: T.untyped).void }
  def self.write_setting(key, value)
    record.update(settings: record.settings.merge(key => value))
  end

  sig { returns(T::Hash[String, T.any(Integer, T::Boolean)]) }
  def self.defaults
    { "read_only_mode" => false, "maximum_concurrent_scrapers" => 20 }
  end

  private_class_method :record, :read_setting, :write_setting, :defaults
end
