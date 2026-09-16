# typed: false
# frozen_string_literal: true

require "spec_helper"

RSpec.describe "GitLab documentation", type: :request do
  it "renders" do
    get gitlab_documentation_index_path

    expect(response).to have_http_status(:success)
    expect(response.body).to include("How morph.io reaches your repositories").and include("Moving a scraper between forges")
  end

  it "is linked from the GitHub App page" do
    get github_app_documentation_index_path

    expect(response.body).to include(gitlab_documentation_index_path)
  end
end
