# typed: strict
# frozen_string_literal: true

# Moves a Scraper from one repository to another, on another forge or the
# same one, keeping the Scraper itself: its URL, data, runs, watchers and
# collaborators. The local clone is thrown away and fetched afresh from the
# new repository. Returns nil on success or a sentence saying why not.
class ChangeRepositoryService
  extend T::Sig

  sig { params(scraper: Scraper, forge: Morph::Forge::Base, full_name: String, user: User).returns(T.nilable(String)) }
  def self.call(scraper, forge, full_name, user)
    identity = user.forge_identity(forge.key)
    return "You have not connected a #{forge.name} account on morph.io." if identity.nil? || identity.access_token.blank?

    owner = T.must(scraper.owner)
    owner_identity = owner.forge_identity(forge.key)
    return "#{owner.nickname} has no #{forge.name} account connected on morph.io." if owner_identity.nil?

    repository = forge.person_client(identity).repository(full_name)
    return "morph.io could not find #{full_name} on #{forge.name} with your account." if repository.nil?
    return "#{full_name} belongs to #{repository.owner_login} on #{forge.name}, not to #{owner_identity.login}." if repository.owner_login != owner_identity.login

    scraper.transaction do
      scraper.update!(
        forge_key: forge.key, forge_repo_id: repository.id, name: repository.name,
        full_name: "#{owner.to_param}/#{repository.name}", repo_url: repository.web_url, git_url: repository.clone_url,
        private: repository.private, permissions_stale_since: nil
      )
      scraper.forge_credentials.destroy_all
    end
    FileUtils.rm_rf(scraper.repo_path)
    scraper.create_create_scraper_progress!(heading: "Moving to #{forge.name}", message: "Queuing", progress: 5)
    CreateFromForgeWorker.perform_async(T.must(scraper.id))
    nil
  end
end
