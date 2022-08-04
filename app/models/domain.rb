# typed: false
# frozen_string_literal: true

# For the benefit of UpdateDomainWorker
require "nokogiri"

# A domain that is scraped by a scraper
class Domain < ApplicationRecord
  # If meta is available use that, otherwise title
  def meta_or_title
    if meta.present?
      meta
    elsif title.present?
      title
    end
  end

  def update_meta!
    update(Domain.lookup_metadata_remote(name))
  end

  def self.lookup_metadata_remote(domain_name)
    doc = RestClient::Resource.new(
      "http://#{domain_name}", verify_ssl: OpenSSL::SSL::VERIFY_NONE
    ).get
    header = Nokogiri::HTML(doc).at("html head")
    if header
      tag = (header.at("meta[name='description']") ||
             header.at("meta[name='Description']"))
    end
    meta = tag["content"] if tag
    title_tag = header.at("title") if header
    title = title_tag.inner_text.strip if title_tag
    { meta: meta, title: title }
  # TODO: If there's an error record that in the database
  # TODO It would be great in case of certain errors to allow retries in some form
  rescue RestClient::InternalServerError, RestClient::BadRequest,
         RestClient::ResourceNotFound, RestClient::Forbidden,
         RestClient::RequestTimeout, RestClient::BadGateway,
         RestClient::ExceptionWithResponse, RestClient::RequestFailed,
         RestClient::ServiceUnavailable, RestClient::ServerBrokeConnection,
         Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EINVAL,
         Errno::EHOSTUNREACH, URI::InvalidURIError, Net::HTTPBadResponse
    { meta: nil, title: nil }
  end
end
