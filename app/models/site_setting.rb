class SiteSetting < ActiveRecord::Base
  serialize :settings

  def self.read_only_mode
    record.settings["read_only_mode"]
  end

  def self.read_only_mode=(mode)
    record.update_attributes(settings: record.settings.merge({"read_only_mode" => mode}))
  end

  def self.record
    SiteSetting.first || SiteSetting.create(settings: {"read_only_mode" => false})
  end
end
