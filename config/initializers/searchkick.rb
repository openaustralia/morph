# frozen_string_literal: true

# Searchkick 5.0.5 hardcodes `Content-Type: application/json`. With
# ELASTIC_CLIENT_APIVERSIONING on, the 7.17 client also sends a vendor
# `Accept: ...; compatible-with=7`, and Elasticsearch 8 rejects the pair with a
# 400 `media_type_header_exception`. Send the matching vendor Content-Type.
# The gem only turns versioning on for "1" or "true", so match it exactly.
if %w[1 true].include?(ENV.fetch("ELASTIC_CLIENT_APIVERSIONING", nil))
  Searchkick.client_options = {
    transport_options: {
      headers: { content_type: "application/vnd.elasticsearch+json; compatible-with=7" }
    }
  }
end
