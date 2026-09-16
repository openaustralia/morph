# typed: false
# frozen_string_literal: true

require "spec_helper"

# OmniAuth 2 only starts the OAuth dance on a POST (CVE-2015-9284), so every
# "Sign in with ..." control has to be a form, and a bare GET to the authorize
# path must not redirect anyone to the forge.
RSpec.describe "Signing in", type: :request do
  def forms_posting_to(path, html)
    Nokogiri::HTML(html).css("form[action='#{path}'][method='post']")
  end

  describe "the sign-in page" do
    it "offers a form that posts to the GitHub authorize path" do
      get "/sign_in"

      expect(forms_posting_to("/users/auth/github", response.body)).not_to be_empty
    end
  end

  describe "the front page when signed out" do
    it "offers 'Get started' as a form that posts to the GitHub authorize path" do
      # The signed-out front page renders `introducing.md` through a partial
      # name with a dot in it, which Rails 6.1 deprecates and the test
      # environment turns into an error. That is nothing to do with sign-in,
      # so it is silenced here rather than fixed here.
      ActiveSupport::Deprecation.silence { get "/" }

      forms = forms_posting_to("/users/auth/github", response.body)
      labels = forms.map { |form| form.at_css("input[type='submit']")["value"] }
      expect(labels).to include("Get started")
    end
  end

  describe "GET to the authorize path" do
    it "is refused rather than starting the OAuth flow" do
      get "/users/auth/github"

      expect(response).to have_http_status(:not_found)
    end
  end
end
