# typed: strict
# frozen_string_literal: true

module Morph
  # Service layer for talking to the Github API. Acts on behalf of a user
  class Github
    extend T::Sig

    sig { returns(User) }
    attr_reader :user

    sig { params(user: User).void }
    def initialize(user)
      @user = user
    end

    # Will create a repository. Works for both an individual and an
    # organisation. Returns a repo
    sig { params(owner: Owner, name: String, description: T.nilable(String), private: T::Boolean).void }
    def create_repository(owner:, name:, description:, private:)
      options = { description: description, private: private, auto_init: true }
      options[:organization] = owner.nickname if user != owner
      user.octokit_client.create_repository(name, options)
    end

    # Returns a list of all public repos. Works for both an individual and
    # an organization. List is sorted by push date
    # TODO: Just pass in nickname of owner
    sig { params(owner: ::Owner).returns(T::Array[T.untyped]) }
    def public_repos(owner)
      if user == owner
        user.octokit_client.repositories(owner.nickname,
                                         sort: :pushed, type: :public)
      else
        # This call doesn't seem to support sort by pushed.
        # So, doing it ourselves
        repos = user.octokit_client.organization_repositories(owner.nickname,
                                                              type: :public)
        repos.sort { |a, b| b.pushed_at.to_i <=> a.pushed_at.to_i }
      end
    end

    sig { returns(T.nilable(String)) }
    def primary_email
      # TODO: If email isn't verified probably should not send email to it
      emails&.find(&:primary)&.email
    end

    # Needs user:email oauth scope for this to work
    # Will return nil if you don't have the right scope
    sig { returns(T.nilable(T::Array[T.untyped])) }
    def emails
      user.octokit_client.emails(accept: "application/vnd.github.v3")
    rescue Octokit::NotFound, Octokit::Unauthorized
      nil
    end

    class Owner < T::Struct
      const :nickname, String
      const :login, String
    end

    class Rel < T::Struct
      const :href, String
    end

    class Rels < T::Struct
      const :html, Rel
      const :git, Rel
    end

    class Repo < T::Struct
      const :owner, Owner
      const :name, String
      const :full_name, String
      const :description, String
      const :id, Integer
      const :rels, Rels
    end

    sig { params(owner: T.untyped).returns(Owner) }
    def new_owner(owner)
      Owner.new(nickname: owner.nickname, login: owner.login)
    end

    sig { params(rel: T.untyped).returns(Rel) }
    def new_rel(rel)
      Rel.new(href: rel.href)
    end

    sig { params(rels: T.untyped).returns(Rels) }
    def new_rels(rels)
      Rels.new(
        html: new_rel(rels[:html]),
        git: new_rel(rels[:git])
      )
    end

    sig { params(repo: T.untyped).returns(Repo) }
    def new_repo(repo)
      Repo.new(
        owner: new_owner(repo.owner),
        name: repo.name,
        full_name: repo.full_name,
        description: repo.description,
        id: repo.id,
        rels: new_rels(repo.rels)
      )
    end

    sig { params(full_name: String).returns(Repo) }
    def repository(full_name)
      new_repo(user.octokit_client.repository(full_name))
    end
  end
end
