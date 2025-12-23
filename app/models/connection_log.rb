# typed: strict
# frozen_string_literal: true

# == Schema Information
#
# Table name: connection_logs
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  domain_id  :integer
#  run_id     :integer
#
# Indexes
#
#  index_connection_logs_on_created_at  (created_at)
#  index_connection_logs_on_domain_id   (domain_id)
#  index_connection_logs_on_run_id      (run_id)
#
# Foreign Keys
#
#  fk_rails_...  (domain_id => domains.id)
#  fk_rails_...  (run_id => runs.id)
#

# A record of an http/https request from a scraper to the outside world
# == Schema Information
#
# Table name: connection_logs
#
#  id         :integer          not null, primary key
#  created_at :datetime
#  domain_id  :integer
#  run_id     :integer
#
# Indexes
#
#  index_connection_logs_on_created_at  (created_at)
#  index_connection_logs_on_domain_id   (domain_id)
#  index_connection_logs_on_run_id      (run_id)
#
# Foreign Keys
#
#  fk_rails_...  (domain_id => domains.id)
#  fk_rails_...  (run_id => runs.id)
#
class ConnectionLog < ApplicationRecord
  extend T::Sig

  DISCARD_AFTER_MONTHS = 12

  sig { returns(T.nilable(String)) }
  attr_reader :ip_address

  sig { params(ip_address: String).void }
  def ip_address=(ip_address)
    @ip_address = T.let(ip_address, T.nilable(String))
  end

  belongs_to :domain
  # It's not actually optional. It hopefully gets set by the callback below
  # TODO: Refactor this not obvious magic. It makes more sense for this lookup to be done outside the model. It smells more of "business" logic
  belongs_to :run, optional: true
  before_save :update_run_id_from_ip_address

  sig { void }
  def update_run_id_from_ip_address
    return if run_id

    run = Run.where(ip_address: ip_address).order(started_at: :desc).first
    self.run_id = run.id if run
  end
end
