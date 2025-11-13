# typed: strict
# frozen_string_literal: true

# Helpers for site details
module SiteHelper
  extend T::Sig

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

  # Returns the appropriate protocol for the current environment
  sig { returns(String) }
  def host_protocol
    Morph::Application.default_url_options[:protocol] || "http"
  end

  # Returns the appropriate [sub] origin for the current environment, a combination of protocol and hostname
  sig { params(sub_domain: T.nilable(String)).returns(String) }
  def host_origin(sub_domain = nil)
    "#{host_protocol}://#{hostname(sub_domain)}"
  end
end
