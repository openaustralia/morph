class Domain < ActiveRecord::Base
  # Lookup and cache meta information for a domain
  def self.lookup_meta(domain_name)
    # TODO If the last time the meta info was grabbed was a long time ago, refresh it
    domain = find_by(name: domain_name)
    if domain.nil?
      doc = RestClient.get("http://#{domain_name}")
      tag = Nokogiri::HTML(doc).at("html head meta[name='Description']")
      meta = tag["content"] if tag
      domain = create!(name: domain_name, meta: meta)
    end
    domain.meta
  end
end
