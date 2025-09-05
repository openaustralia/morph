#!/bin/bash
set -ex

# Remove a potentially pre-existing server.pid for Rails.
# rm -f /app/tmp/pids/server.pid

# rake db:schema:load
# rake db:migrate

exec "$@"
