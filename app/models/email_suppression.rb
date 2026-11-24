# typed: strict
# frozen_string_literal: true

# An email address that alert emails are no longer sent to, because it hard-bounced in Postal. Not the same thing as
# Postal's own per-mail-server suppression list (see GLOSSARY.md).
#
# It belongs to the address, not to a User, so a person who changes their GitHub primary email is no longer affected,
# and one who changes back is. Lifting keeps the row, and a later hard bounce suppresses the same row again with the
# new date and reply, so only the latest bounce is recorded.
#
# == Schema Information
#
# Table name: email_suppressions
#
#  id            :bigint           not null, primary key
#  address       :string(255)      not null
#  lifted_at     :datetime
#  postal_event  :string(255)
#  reason        :string(255)      not null
#  reply_excerpt :string(255)
#  suppressed_at :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_email_suppressions_on_address  (address) UNIQUE
#
class EmailSuppression < ApplicationRecord
  extend T::Sig

  REPLY_EXCERPT_LENGTH = 255

  enum :reason, { hard_bounce: "hard_bounce", imported_from_postal: "imported_from_postal" }

  before_validation :normalise_address

  validates :address, :suppressed_at, presence: true
  validates :address, uniqueness: true

  scope :active, -> { where(lifted_at: nil) }

  # Lower-cased and trimmed, with any display name removed, so Alice@Example.org and "Alice <alice@example.org>" are one
  # address. Blank if the text isn't an address.
  sig { params(address: T.nilable(String)).returns(String) }
  def self.normalise(address)
    normalised = begin
      Mail::Address.new(address.to_s).address.to_s.strip.downcase
    rescue Mail::Field::ParseError
      address.to_s.strip.downcase
    end
    # Something with no @ isn't an address (for example "<>"), so there is nothing to suppress
    normalised.include?("@") ? normalised : ""
  end

  sig { params(address: T.nilable(String)).returns(T::Boolean) }
  def self.suppressed?(address)
    return false if address.blank?

    active.exists?(address: normalise(address))
  end

  sig { params(address: T.nilable(String)).returns(T.nilable(EmailSuppression)) }
  def self.active_for(address)
    return nil if address.blank?

    active.find_by(address: normalise(address))
  end

  # Suppresses the address, or suppresses it again if a lift had cleared it. Safe to repeat, so a retried or duplicate
  # Postal event does no harm.
  sig do
    params(address: String, reason: Symbol, postal_event: T.nilable(String), reply: T.nilable(String),
           at: ActiveSupport::TimeWithZone).returns(EmailSuppression)
  end
  def self.suppress!(address, reason:, postal_event: nil, reply: nil, at: Time.zone.now)
    suppression = find_or_initialize_by(address: normalise(address))
    return suppression if suppression.persisted? && suppression.lifted_at.nil?

    suppression.update!(reason: reason, postal_event: postal_event, reply_excerpt: excerpt(reply),
                        suppressed_at: at, lifted_at: nil)
    suppression
  rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
    # Two events for one address handled at once. The other one won, which is the outcome we wanted.
    raise unless exists?(address: normalise(address))

    T.must(find_by(address: normalise(address)))
  end

  # The table is utf8 (3 bytes a character), so a character outside the Basic Multilingual Plane, such as an emoji in a
  # remote server's reply, would make the write fail and the address would never be suppressed.
  sig { params(reply: T.nilable(String)).returns(T.nilable(String)) }
  def self.excerpt(reply)
    return nil if reply.nil?

    reply.scrub("?").gsub(/[^\u{0}-\u{FFFF}]/, "?").truncate(REPLY_EXCERPT_LENGTH)
  end

  # When staff last cleared the address, if they ever did. An old export mustn't suppress it again.
  sig { params(address: String).returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def self.last_lifted_at(address)
    where(address: normalise(address)).maximum(:lifted_at)
  end

  # Returns how many active suppressions were lifted (0 or 1).
  sig { params(address: String).returns(Integer) }
  def self.lift!(address)
    active.where(address: normalise(address)).update_all(lifted_at: Time.zone.now) # rubocop:disable Rails/SkipsModelValidations
  end

  private

  sig { void }
  def normalise_address
    self.address = self.class.normalise(address)
  end
end
