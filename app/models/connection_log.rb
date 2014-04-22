class ConnectionLog < ActiveRecord::Base
  attr_accessor :ip_address

  before_save :update_run_id_from_ip_address

  def update_run_id_from_ip_address
    if run_id.nil?
      self.run_id = Run.where(ip_address: self.ip_address).order(started_at: :desc).first.id
    end
  end
end
