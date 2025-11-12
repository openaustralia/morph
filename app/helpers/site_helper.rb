# typed: strict
# frozen_string_literal: true

# Helpers for site details
module SiteHelper
  # Returns the appropriate [sub] hostname for the current environment
  sig { params(sub_domain: T.nilable(String)).returns(String) }
  def hostname(sub_domain = nil)
    domain = Morph::Application.default_url_options[:host] || "morph.io"
    if domain.include?("localhost") || sub_domain.blank?
      domain
    else
      "#{sub_domain}.#{domain}"
    end
  end
end
