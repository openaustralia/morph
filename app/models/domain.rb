# For the benefit of UpdateDomainWorker
require "nokogiri"

class Domain < ActiveRecord::Base
  # If meta is available use that, otherwise title
  def meta_or_title
    if meta.present?
      meta
    elsif title.present?
      title
    end
  end

  def update_meta!
    update_attributes(Domain.lookup_metadata_remote(name))
  end

  def self.lookup_metadata_remote(domain_name)
    begin
      doc = RestClient::Resource.new("http://#{domain_name}", verify_ssl: OpenSSL::SSL::VERIFY_NONE).get
      header = Nokogiri::HTML(doc).at("html head")
      tag = (header.at("meta[name='description']") || header.at("meta[name='Description']")) if header
      meta = tag["content"] if tag
      title_tag = header.at("title") if header
      title = title_tag.inner_text.strip if title_tag
      {meta: meta, title: title}
    # TODO If there's an error record that in the database
    rescue RestClient::InternalServerError, RestClient::BadRequest, RestClient::ResourceNotFound, RestClient::Forbidden, RestClient::RequestTimeout, RestClient::BadGateway, RestClient::MaxRedirectsReached, RestClient::RequestFailed, RestClient::ServiceUnavailable, Errno::ECONNREFUSED, Errno::ECONNRESET, Errno::EINVAL, Errno::EHOSTUNREACH, URI::InvalidURIError
      {meta: nil, title: nil}
    end
  end
end
