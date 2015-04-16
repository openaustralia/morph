class NewDomainWorker
  include Sidekiq::Worker

  # Look up meta info for a domain
  def perform(domain_name)
    doc = RestClient.get("http://#{domain_name}")
    tag = Nokogiri::HTML(doc).at("html head meta[name='Description']")
    meta = tag["content"] if tag
    Domain.create!(name: domain_name, meta: meta)
  end
end
