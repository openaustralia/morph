class SiteSetting < ActiveRecord::Base
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

  private
  
  def self.record
    SiteSetting.first || SiteSetting.create(settings: defaults)
  end

  def self.read_setting(key)
    record.settings[key]
  end

  def self.write_setting(key, value)
    record.update_attributes(settings: record.settings.merge({key => value}))
  end

  def self.defaults
    {"read_only_mode" => false}
  end
end
