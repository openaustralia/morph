# typed: strict
# frozen_string_literal: true

# For the benefit of UpdateDomainWorker
require "nokogiri"

# A domain that is scraped by a scraper
class Domain < ApplicationRecord
  extend T::Sig

  has_many :connection_logs, dependent: :destroy

  # If meta is available use that, otherwise title
  sig { returns(T.nilable(String)) }
  def meta_or_title
    if meta.present?
      meta
    elsif title.present?
      title
    end
  end

  sig { void }
  def update_meta!
    r = Domain.lookup_metadata_remote(name)
    update(meta: r.meta, title: r.title)
  end

  class MetaTitleStruct < T::Struct
    const :meta, T.nilable(String)
    const :title, T.nilable(String)
  end

  sig { params(domain_name: String).returns(MetaTitleStruct) }
  def self.lookup_metadata_remote(domain_name)
    doc = RestClient::Resource.new(
      "http://#{domain_name}", verify_ssl: OpenSSL::SSL::VERIFY_NONE
    ).get
    header = Nokogiri::HTML(doc).at("html head")
    if header
      tag = header.at("meta[name='description']") ||
            header.at("meta[name='Description']")
    end
    meta = tag["content"] if tag
    title_tag = header.at("title") if header
    title = title_tag.inner_text.strip if title_tag
    MetaTitleStruct.new(meta: meta, title: title)
  # TODO: If there's an error record that in the database
  # TODO It would be great in case of certain errors to allow retries in some form
  rescue RestClient::InternalServerError, RestClient::BadRequest,
         RestClient::ResourceNotFound, RestClient::Forbidden,
         RestClient::RequestTimeout, RestClient::BadGateway,
         RestClient::ExceptionWithResponse, RestClient::RequestFailed,
         RestClient::ServiceUnavailable, RestClient::ServerBrokeConnection,
         Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EINVAL,
         Errno::EHOSTUNREACH, URI::InvalidURIError, Net::HTTPBadResponse
    MetaTitleStruct.new(meta: nil, title: nil)
  end
end
