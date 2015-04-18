class NewDomainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  # Look up meta info for a domain
  def perform(domain_name)
    Domain.lookup_meta(domain_name)
  end
end
