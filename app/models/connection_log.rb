# frozen_string_literal: true

# A record of an http/https request from a scraper to the outside world
class ConnectionLog < ActiveRecord::Base
  attr_accessor :ip_address

  belongs_to :domain
  belongs_to :run
  before_save :update_run_id_from_ip_address

  def update_run_id_from_ip_address
    return if run_id

    run = Run.where(ip_address: ip_address).order(started_at: :desc).first
    self.run_id = run.id if run
  end
end
