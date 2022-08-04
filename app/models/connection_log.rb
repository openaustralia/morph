# typed: true
# frozen_string_literal: true

# A record of an http/https request from a scraper to the outside world
class ConnectionLog < ApplicationRecord
  attr_accessor :ip_address

  belongs_to :domain
  # It's not actually optional. It hopefully gets set by the callback below
  # TODO: Refactor this not obvious magic. It makes more sense for this lookup to be done outside the model. It smells more of "business" logic
  belongs_to :run, optional: true
  before_save :update_run_id_from_ip_address

  def update_run_id_from_ip_address
    return if run_id

    run = Run.where(ip_address: ip_address).order(started_at: :desc).first
    self.run_id = run.id if run
  end
end
