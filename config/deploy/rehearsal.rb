# typed: false
# frozen_string_literal: true

# The rehearsal server for the move to Ubuntu 26.04 (#1579), at new.morph.io.
#
# This stage is retired at cutover. The first production deploy goes straight to
# /srv/www/production in the window, from a new production stage added by the
# cutover merge, and the rehearsal directory is not renamed. Delete this file
# and its spec then, along with the rehearsal names, basic auth, mail sink and
# switches in the infrastructure repository.
#
# nginx basic auth, the scheduled jobs switch (cron_enabled) and the mail sink
# are set up in the infrastructure repository and the server's .env, not here.
set :stage, :rehearsal
set :rails_env, :production

role :app, %w[deploy@new.morph.io]
role :web, %w[deploy@new.morph.io]
role :db,  %w[deploy@new.morph.io]

# This stage uses rbenv and /srv/www/<stage>. The staging and local stages keep the
# rvm and /var/www defaults from deploy.rb (#1575, #1595).
set :rbenv_type, :user
set :rbenv_ruby, File.read(File.expand_path("../../.ruby-version", __dir__)).strip
set :deploy_to, "/srv/www/rehearsal"

# The SQLite scraper data lives in one directory outside both stages, linked into
# shared/db/scrapers, so retiring this stage never copies it (lib/capistrano/tasks/
# scrapers_data_dir.cap). The path must match the infrastructure repository's morph role.
# The production stage sets the same path.
set :scrapers_data_dir, "/srv/www/data/scrapers"

# The post-deploy queue fix would re-enqueue the restored production database's
# unfinished runs, which means running real scrapers (#1567). Skip it here.
set :fix_queue_run_inconsistencies, false

# No deploy tags for rehearsal. capistrano-tagging3 would push a rehearsal_<release>
# tag to origin on each deploy and delete old ones. Other stages keep their tags.
%w[tagging3:deploy tagging3:cleanup].each { |name| Rake::Task[name].clear_actions }
