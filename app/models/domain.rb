# For the benefit of NewDomainWorker
require "nokogiri"

class Domain < ActiveRecord::Base
  # Lookup and cache meta information for a domain
  def self.lookup_meta(domain_name)
    # TODO If the last time the meta info was grabbed was a long time ago, refresh it
    domain = ActiveRecord::Base.transaction do
      find_by(name: domain_name) || create!(name: domain_name, meta: lookup_meta_remote(domain_name))
    end
    domain.meta
  end

  def self.lookup_meta_remote(domain_name)
    lookup_metadata_remote(domain_name)[:meta]
  end

  def self.lookup_metadata_remote(domain_name)
    begin
      doc = RestClient::Resource.new("http://#{domain_name}", verify_ssl: OpenSSL::SSL::VERIFY_NONE).get
      header = Nokogiri::HTML(doc).at("html head")
      tag = header.at("meta[name='description']") || header.at("meta[name='Description']")
      meta = tag["content"] if tag
      {meta: meta}
    rescue RestClient::InternalServerError, RestClient::BadRequest, RestClient::ResourceNotFound, RestClient::Forbidden, Errno::ECONNREFUSED
      {meta: nil}
    end
  end
end
