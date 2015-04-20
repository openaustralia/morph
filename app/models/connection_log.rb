class ConnectionLog < ActiveRecord::Base
  attr_accessor :ip_address
  belongs_to :domain

  before_save :update_run_id_from_ip_address

  def update_run_id_from_ip_address
    if run_id.nil?
      run = Run.where(ip_address: self.ip_address).order(started_at: :desc).first
      self.run_id = run.id if run
    end
  end
end
