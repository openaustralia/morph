class UpdateDomainWorker
  include Sidekiq::Worker
  sidekiq_options queue: :small

  # Look up meta info for a domain
  def perform(domain_name)
    Domain.find_by(name: domain_name).update_meta!
  end
end
