# typed: strict
# frozen_string_literal: true

module Morph
  # The handful of GitLab REST API v4 calls morph.io makes, over Faraday.
  # The `gitlab` gem wants Ruby 3.1, which is why this exists.
  #
  # Every call authenticates with whatever token it is given: a user's OAuth
  # token, a group access token or (for clone only, never here) a deploy
  # token. Which one is the caller's business (ADR 0007).
  class GitlabClient
    extend T::Sig

    class Error < StandardError; end
    class NotFound < Error; end
    class Unauthorized < Error; end
    class Forbidden < Error; end

    # GitLab's numeric access levels. Planner (15) and Security Manager (25)
    # are specialised roles that are not cumulative; they fall where their
    # number puts them.
    GUEST = 10
    REPORTER = 20
    DEVELOPER = 30
    MAINTAINER = 40
    OWNER = 50

    class Namespace < T::Struct
      const :id, Integer
      const :path, String
      const :group, T::Boolean
    end

    class Project < T::Struct
      const :id, Integer
      const :path, String
      const :full_path, String
      const :description, T.nilable(String)
      const :private, T::Boolean
      const :default_branch, T.nilable(String)
      const :web_url, String
      const :http_url_to_repo, String
      const :namespace, Namespace
    end

    class Member < T::Struct
      const :id, Integer
      const :username, String
      const :access_level, Integer
    end

    class Group < T::Struct
      const :id, Integer
      const :path, String
      const :name, String
      const :web_url, String
      const :avatar_url, T.nilable(String)
      const :description, T.nilable(String)
    end

    class User < T::Struct
      const :id, Integer
      const :username, String
      const :name, T.nilable(String)
      const :email, T.nilable(String)
      const :avatar_url, T.nilable(String)
      const :web_url, T.nilable(String)
      const :website_url, T.nilable(String)
      const :organization, T.nilable(String)
      const :location, T.nilable(String)
    end

    class Token < T::Struct
      const :id, Integer
      const :token, String
      const :username, T.nilable(String)
      const :expires_at, T.nilable(Date)
    end

    sig { params(access_token: String).void }
    def initialize(access_token:)
      @access_token = access_token
    end

    sig { returns(User) }
    def current_user
      build_user(get("user"))
    end

    sig { params(id_or_path: T.any(Integer, String)).returns(T.nilable(Project)) }
    def project(id_or_path)
      build_project(get("projects/#{encode(id_or_path)}"))
    rescue NotFound
      nil
    end

    sig { params(project_id: Integer).returns(T::Array[Member]) }
    def members(project_id)
      paginate("projects/#{project_id}/members/all").map do |m|
        Member.new(id: m["id"], username: m["username"], access_level: m["access_level"])
      end
    end

    sig { params(user_id: Integer).returns(T::Array[Project]) }
    def user_projects(user_id)
      paginate("users/#{user_id}/projects", order_by: "last_activity_at", sort: "desc").map { |p| build_project(p) }
    end

    sig { params(group_id: Integer).returns(T::Array[Project]) }
    def group_projects(group_id)
      paginate("groups/#{group_id}/projects", order_by: "last_activity_at", sort: "desc", include_subgroups: false).map { |p| build_project(p) }
    end

    # initialize_with_readme gives the project a default branch, which
    # commit_files needs to exist.
    sig { params(path: String, description: T.nilable(String), private: T::Boolean, namespace_id: T.nilable(Integer)).returns(Project) }
    def create_project(path:, description:, private:, namespace_id:)
      body = { path: path, description: description, visibility: private ? "private" : "public", initialize_with_readme: true }
      body[:namespace_id] = namespace_id if namespace_id
      build_project(post("projects", body))
    end

    sig { params(project_id: Integer, branch: String, message: String, files: T::Hash[String, String]).void }
    def commit_files(project_id, branch:, message:, files:)
      actions = files.map { |file_path, content| { action: "create", file_path: file_path, content: content } }
      post("projects/#{project_id}/repository/commits", { branch: branch, commit_message: message, actions: actions })
    end

    sig { params(project_id: Integer, private: T::Boolean).void }
    def set_visibility(project_id, private:)
      put("projects/#{project_id}", { visibility: private ? "private" : "public" })
    end

    # Top-level groups only: subgroups do not map onto Organizations.
    sig { returns(T::Array[Group]) }
    def groups
      paginate("groups", min_access_level: GUEST, top_level_only: true).map { |g| build_group(g) }
    end

    sig { params(id_or_path: T.any(Integer, String)).returns(T.nilable(Group)) }
    def group(id_or_path)
      build_group(get("groups/#{encode(id_or_path)}"))
    rescue NotFound
      nil
    end

    sig { params(username: String).returns(T.nilable(User)) }
    def user(username)
      found = get("users", username: username)
      found.empty? ? nil : build_user(found.first)
    end

    # Premium and Ultimate only on gitlab.com: Forbidden elsewhere.
    sig { params(group_id: Integer, name: String, expires_at: Date).returns(Token) }
    def create_group_access_token(group_id, name:, expires_at:)
      build_token(post("groups/#{group_id}/access_tokens",
                       { name: name, access_level: REPORTER, scopes: %w[read_api read_repository], expires_at: expires_at.iso8601 }))
    end

    # Rotating invalidates the old token and returns a new one under a new id.
    sig { params(group_id: Integer, token_id: Integer, expires_at: Date).returns(Token) }
    def rotate_group_access_token(group_id, token_id, expires_at:)
      build_token(post("groups/#{group_id}/access_tokens/#{token_id}/rotate", { expires_at: expires_at.iso8601 }))
    end

    sig { params(group_id: Integer, name: String).returns(Token) }
    def create_group_deploy_token(group_id, name:)
      build_token(post("groups/#{group_id}/deploy_tokens", { name: name, scopes: ["read_repository"] }))
    end

    sig { params(project_id: Integer, name: String).returns(Token) }
    def create_project_deploy_token(project_id, name:)
      build_token(post("projects/#{project_id}/deploy_tokens", { name: name, scopes: ["read_repository"] }))
    end

    private

    sig { returns(Faraday::Connection) }
    def connection
      @connection ||= T.let(Faraday.new(url: "#{Morph::Environment.gitlab_url}/api/v4/") do |f|
        f.request :json
        f.response :json
        f.headers["Authorization"] = "Bearer #{@access_token}"
      end, T.nilable(Faraday::Connection))
    end

    sig { params(path: String, params: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
    def get(path, params = {})
      handle(connection.get(path, params)).body
    end

    sig { params(path: String, body: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
    def post(path, body)
      handle(connection.post(path, body)).body
    end

    sig { params(path: String, body: T::Hash[Symbol, T.untyped]).returns(T.untyped) }
    def put(path, body)
      handle(connection.put(path, body)).body
    end

    sig { params(path: String, params: T::Hash[Symbol, T.untyped]).returns(T::Array[T.untyped]) }
    def paginate(path, params = {})
      results = []
      page = 1
      loop do
        response = handle(connection.get(path, params.merge(per_page: 100, page: page)))
        results.concat(response.body)
        next_page = response.headers["X-Next-Page"].presence
        break if next_page.nil?

        page = next_page.to_i
      end
      results
    end

    sig { params(response: Faraday::Response).returns(Faraday::Response) }
    def handle(response)
      case response.status
      when 200..299 then response
      when 401 then raise Unauthorized, describe(response)
      when 403 then raise Forbidden, describe(response)
      when 404 then raise NotFound, describe(response)
      else raise Error, describe(response)
      end
    end

    sig { params(response: Faraday::Response).returns(String) }
    def describe(response)
      message = response.body.is_a?(Hash) ? response.body["message"] || response.body["error"] : response.body
      "GitLab #{response.status}: #{message}"
    end

    sig { params(id_or_path: T.any(Integer, String)).returns(String) }
    def encode(id_or_path)
      id_or_path.is_a?(Integer) ? id_or_path.to_s : ERB::Util.url_encode(id_or_path)
    end

    sig { params(attrs: T.untyped).returns(Project) }
    def build_project(attrs)
      ns = attrs["namespace"]
      Project.new(
        id: attrs["id"], path: attrs["path"], full_path: attrs["path_with_namespace"], description: attrs["description"],
        private: attrs["visibility"] == "private", default_branch: attrs["default_branch"],
        web_url: attrs["web_url"], http_url_to_repo: attrs["http_url_to_repo"],
        namespace: Namespace.new(id: ns["id"], path: ns["path"], group: ns["kind"] == "group")
      )
    end

    sig { params(attrs: T.untyped).returns(Group) }
    def build_group(attrs)
      Group.new(id: attrs["id"], path: attrs["path"], name: attrs["name"], web_url: attrs["web_url"], avatar_url: attrs["avatar_url"], description: attrs["description"])
    end

    sig { params(attrs: T.untyped).returns(User) }
    def build_user(attrs)
      User.new(id: attrs["id"], username: attrs["username"], name: attrs["name"], email: attrs["email"] || attrs["public_email"].presence,
               avatar_url: attrs["avatar_url"], web_url: attrs["web_url"], website_url: attrs["website_url"].presence,
               organization: attrs["organization"].presence, location: attrs["location"].presence)
    end

    sig { params(attrs: T.untyped).returns(Token) }
    def build_token(attrs)
      Token.new(id: attrs["id"], token: attrs["token"], username: attrs["username"], expires_at: attrs["expires_at"] ? Date.parse(attrs["expires_at"]) : nil)
    end
  end
end
