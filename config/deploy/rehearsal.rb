# typed: false
# frozen_string_literal: true

# The rehearsal server for the move to Ubuntu 26.04 (#1579). It is the server
# that becomes production at cutover, when this stage is renamed to production.
# nginx basic auth, the scheduled jobs switch and the mail sink are set up in
# the shared infrastructure repository and the server's .env, not here.
set :stage, :rehearsal
set :rails_env, :production

role :app, %w[deploy@new.morph.io]
role :web, %w[deploy@new.morph.io]
role :db,  %w[deploy@new.morph.io]

# The post-deploy queue fix would re-enqueue the restored production database's
# unfinished runs, which means running real scrapers (#1567). Skip it here.
set :fix_queue_run_inconsistencies, false
