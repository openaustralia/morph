# typed: true
# frozen_string_literal: true

# Settings that apply to the whole app and everybody on it
class SiteSetting < ApplicationRecord
  serialize :settings

  def self.read_only_mode
    read_setting("read_only_mode")
  end

  def self.read_only_mode=(mode)
    write_setting("read_only_mode", mode)
  end

  def self.toggle_read_only_mode!
    self.read_only_mode = !read_only_mode
  end

  def self.maximum_concurrent_scrapers
    read_setting("maximum_concurrent_scrapers").to_i
  end

  def self.maximum_concurrent_scrapers=(number)
    write_setting("maximum_concurrent_scrapers", number)
    update_sidekiq_maximum_concurrent_scrapers!
  end

  def self.update_sidekiq_maximum_concurrent_scrapers!
    Sidekiq::Queue["scraper"].limit = maximum_concurrent_scrapers
  end

  def self.record
    SiteSetting.first || SiteSetting.create(settings: defaults)
  end

  def self.read_setting(key)
    record.settings[key] || defaults[key]
  end

  def self.write_setting(key, value)
    record.update(settings: record.settings.merge(key => value))
  end

  def self.defaults
    { "read_only_mode" => false, "maximum_concurrent_scrapers" => 20 }
  end

  private_class_method :record, :read_setting, :write_setting, :defaults
end
