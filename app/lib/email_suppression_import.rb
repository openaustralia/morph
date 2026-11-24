# typed: strict
# frozen_string_literal: true

require "csv"

# One-off clean-up that suppresses addresses Postal has already hard-failed, so the damage stops before the webhook is
# switched on. Applies the same rule as the webhook (PostalWebhook::BounceRule), and additionally skips rows with no
# reply from the receiving server, because a failure with no reply (for example Postal's own outbound spam check) says
# nothing about the address.
#
# The input is a CSV export from the Postal server's history with a header row. Columns (names are case-insensitive):
#   address (or rcpt_to)   the recipient
#   output (or reply)      the receiving server's reply, exactly as Postal stored it
#   date (or timestamp)    optional, when the most recent hard fail happened
#
# The export must hold hard failures only: this doesn't check the event, so a row for mail that was delivered, or that
# soft-failed, would suppress a working address.
#
# The file is real personal data: keep it out of the repository (tmp/ is ignored), issues, chat and AI conversations.
# Safe to run twice. Returns counts only so the output can be shared without exposing an address.
#
# Adapted from They Vote for You's EmailSuppressionImport (openaustralia/theyvoteforyou, same licence).
class EmailSuppressionImport
  extend T::Sig

  # Raised, with column names only, when the file doesn't have the columns we need. Better than counting every row as
  # missing data, which would look like a successful run that did nothing.
  class MissingColumns < StandardError; end

  ADDRESS_COLUMNS = T.let(%w[address rcpt_to].freeze, T::Array[String])
  REPLY_COLUMNS = T.let(%w[output reply].freeze, T::Array[String])
  DATE_COLUMNS = T.let(%w[date timestamp].freeze, T::Array[String])

  OUTCOMES = T.let(%i[suppressed already_suppressed skipped_failed_before_a_lift skipped_refusal_blaming_our_server
                      skipped_no_reply skipped_no_address].freeze, T::Array[Symbol])

  sig { params(path: String).returns(T::Hash[Symbol, Integer]) }
  def self.call(path)
    new.call(path)
  end

  sig { params(path: String).returns(T::Hash[Symbol, Integer]) }
  def call(path)
    check_columns!(path)
    counts = OUTCOMES.index_with { 0 }
    CSV.foreach(path, encoding: "bom|utf-8", headers: true, header_converters: ->(header) { normalise_header(header) }) do |row|
      outcome = outcome_for(row)
      counts[outcome] = T.must(counts[outcome]) + 1
    end
    counts
  end

  private

  sig { params(header: T.untyped).returns(String) }
  def normalise_header(header)
    header.to_s.strip.downcase
  end

  sig { params(path: String).void }
  def check_columns!(path)
    headers = (CSV.parse_line(File.open(path, encoding: "bom|utf-8", &:gets).to_s) || []).map { |header| normalise_header(header) }
    return if headers.intersect?(ADDRESS_COLUMNS) && headers.intersect?(REPLY_COLUMNS)

    raise MissingColumns, "The file needs a header row with a column named #{ADDRESS_COLUMNS.join(' or ')} " \
                          "and a column named #{REPLY_COLUMNS.join(' or ')}"
  end

  sig { params(row: CSV::Row).returns(Symbol) }
  def outcome_for(row)
    address = row["address"] || row["rcpt_to"]
    reply = row["output"] || row["reply"]
    return :skipped_no_address if EmailSuppression.normalise(address).blank?
    return :skipped_no_reply if reply.blank?
    return :skipped_refusal_blaming_our_server if PostalWebhook::BounceRule.blames_sender?(reply)
    return :already_suppressed if EmailSuppression.suppressed?(address)

    failed_at = failed_at(row)
    return :skipped_failed_before_a_lift if recovered_since?(address, failed_at)

    EmailSuppression.suppress!(address, reason: :imported_from_postal, reply: reply, at: failed_at || Time.zone.now)
    :suppressed
  end

  # When the most recent hard fail happened, so a person's notice says since when their emails have been returning.
  # Nil if the file has no usable date.
  sig { params(row: CSV::Row).returns(T.nilable(ActiveSupport::TimeWithZone)) }
  def failed_at(row)
    Time.zone.parse(row.values_at(*DATE_COLUMNS).find(&:present?).to_s)
  rescue ArgumentError
    nil
  end

  # An address someone has since proved works again (a lift) must not be suppressed again by an old export. Without a
  # date we can't tell whether the failure was before or after, so we leave it alone.
  sig { params(address: String, failed_at: T.nilable(ActiveSupport::TimeWithZone)).returns(T::Boolean) }
  def recovered_since?(address, failed_at)
    lifted_at = EmailSuppression.last_lifted_at(address)
    !lifted_at.nil? && (failed_at.nil? || failed_at <= lifted_at)
  end
end
