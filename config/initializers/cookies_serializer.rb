# Be sure to restart your server when you modify this file.

# Specify a serializer for the signed and encrypted cookie jars.
# Valid options are :json, :marshal, and :hybrid.
# FIXME: Change to :json 1 hour after after next deploy (for seamless upgrade of user session cookies)
Rails.application.config.action_dispatch.cookies_serializer = :hybrid
