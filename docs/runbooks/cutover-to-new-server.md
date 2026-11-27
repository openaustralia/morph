# Cutover runbook: move morph.io to the new server

This runbook is the step-by-step plan for the day morph.io and help.morph.io move from the Ubuntu 16.04 Linode (the old server) to the Ubuntu 26.04 Linode (the new server). It is written for #1592, part of the spec in #1579.

It links to the decisions instead of restating them. The map [#1557](https://github.com/openaustralia/morph/issues/1557) lists every closed decision ticket. Where a closed ticket holds more detail than this file, the closed ticket wins, and this file is what needs fixing. The spec [#1579](https://github.com/openaustralia/morph/issues/1579) and the resolution on [#1573](https://github.com/openaustralia/morph/issues/1573) were amended on 2026-11-27, and this runbook follows those amendments.

## How to read this runbook

Every step has an **Action** (what to do, with no one named) and a **Check** (what proves it worked). Steps that can be undone say where. Four rollback points, R0 to R3, are marked in the sequence, and the [rollback section](#rollback) says what each one costs.

Claims are marked so nobody mistakes a guess for a fact:

- **Verified** means checked against this repository on the date in the [status section](#status-of-claims-in-this-runbook).
- **From #NNNN** means taken from a decision ticket or the spec and not checkable from this repository, because it lives in the `openaustralia/infrastructure` repository (on GitLab), in [Terraform](https://developer.hashicorp.com/terraform) or in a person's account.
- **Inferred** means this runbook joined the dots and no ticket says it. Confirm it in a dry run.

Public repository rules apply. Do not put credentials, IP addresses, the announcement text or anyone's name or availability in this file. The new scraper IP address goes in the announcement, which is approved separately and is not committed ([#1576](https://github.com/openaustralia/morph/issues/1576)).

## Terms

- **Window**: the announced maintenance period. It starts after the 10:00 AEDT cron and runs for the second dry run's measured time plus 50% ([#1576](https://github.com/openaustralia/morph/issues/1576)).
- **New server**: the Ubuntu 26.04 Linode. It runs the **rehearsal stage** for the dry runs, then the production stage from cutover. The glossary defines the rehearsal stage and says morph.io has no staging environment ([GLOSSARY.md](../../GLOSSARY.md)).
- **Data directory**: the one directory, outside both the rehearsal and the production stage, that holds the SQLite scraper data (for example `/srv/www/data/scrapers`; the real path is set by the roles in the infrastructure repository). Each stage's `shared/db/scrapers` is a link to it, so the data is never copied twice ([#1579](https://github.com/openaustralia/morph/issues/1579) as amended). The bulk copy, the final delta and the retirement of the rehearsal stage all use it, see steps 2, 3 and 7.
- **Read-only mode**: `SiteSetting.read_only_mode`. It blocks people from creating, editing or deleting scrapers and from resetting API keys. It does **not** stop scraper runs that are already queued or running, which is why the freeze also turns cron off and drains the queue ([#1569](https://github.com/openaustralia/morph/issues/1569)). Verified in [`app/models/site_setting.rb`](../../app/models/site_setting.rb), `app/abilities/` and [`app/workers/scraper_auto_run_worker.rb`](../../app/workers/scraper_auto_run_worker.rb). It does not yet refuse sign-ups, see [writes during the window](#writes-during-the-window).
- **Smoke test**: the checklist in `docs/rehearsal-smoke-test.md` on the branch of [PR #1615](https://github.com/openaustralia/morph/pull/1615). It is not on this branch yet, so it is named by path and is not copied here. Link it once that pull request merges. Step 4 lists only what is different at cutover.

## Writes during the window

Nothing may be written on the old server after the final dump starts, because anything written there afterwards never reaches the new server. These controls hold that line:

| Control | Where | Status |
| --- | --- | --- |
| Site read-only mode on | old server | Verified to exist. Blocks scraper and API-key changes only |
| Site read-only mode also refuses new sign-ups | old and new server | **Not yet built.** A separate code change, not in this pull request, and no tracking issue is linked yet. A prerequisite, see the gates |
| Discourse read-only mode on from the start of the final dump | Discourse | From #1579. Mechanism unverified here |
| `cron_enabled` off | old server | From #1573 and #1567 |
| `scraper` queue drained, workers stopped | old server | Verified queue names, see step 1 |

Why the sign-up refusal matters: read-only mode does not stop GitHub sign-in today. `User.find_for_github_oauth` creates or updates a user, and no controller other than the API run endpoint checks read-only mode (verified in [`app/models/user.rb`](../../app/models/user.rb) and the controllers). Without the change, an account created on the old server after the final dump is lost, and one created on the new server after the flip is lost on rollback (R2).

The only writes allowed on the new server before the flip are the throwaway test scraper and the test account sign-in from the smoke test, the one documented exception in step 4. They are deleted before the flip.

## Go and no-go gates before the window

Do not announce a date until the first group is true, and do not start the window until all of them are true. Each is a check, not a step.

**Before announcing**

- [ ] The second full dry run finished every in-window step in 4 hours or less ([#1569](https://github.com/openaustralia/morph/issues/1569)). The dry runs include the first deploy into an empty stage directory and time it (see step 2).
- [ ] A restic restore drill passed on the rehearsal stage against a **throwaway** restic repository, with its own repository and password. Restore a sample of SQLite files and the latest MySQL dump, load the dump into MySQL, and check row counts ([#1574](https://github.com/openaustralia/morph/issues/1574), as amended in [#1579](https://github.com/openaustralia/morph/issues/1579)). Never use the production repository or credentials for this. They do not exist on the rehearsal stage and are used only from cutover night. The throwaway repository's location is not specified, so keep it clearly separate from the production backup bucket and delete it after the drill (inferred).
- [ ] Each dry-run restore was followed by the scrub, and the scrub has the widened scope in [step 3](#3-final-data-move-and-production-settings). It is never run at cutover.
- [ ] The Discourse trial restore passed ([#1563](https://github.com/openaustralia/morph/issues/1563), [#1569](https://github.com/openaustralia/morph/issues/1569)).
- [ ] The full `log_lines` archive restored on the rehearsal stage and a re-run of the load changed nothing ([#1601](https://github.com/openaustralia/morph/issues/1601)).
- [ ] The rehearsal checks in [#1600](https://github.com/openaustralia/morph/issues/1600) passed, including the container-to-host exposure check that decision left open.
- [ ] The layout change on `main` that shows the read-only notice to **all** visitors has landed ([#1576](https://github.com/openaustralia/morph/issues/1576)). Verified as still outstanding when this runbook was written: [`app/views/layouts/application.html.haml`](../../app/views/layouts/application.html.haml) shows the notice only when `signed_in? && SiteSetting.read_only_mode`.
- [ ] The code change that makes read-only mode refuse new sign-ups has shipped (**not yet built**, see [writes during the window](#writes-during-the-window)), so the announcement can say why.
- [ ] The announcement text is approved, with the date, window length and new scraper address in it ([#1576](https://github.com/openaustralia/morph/issues/1576)). Not committed here.

**Before the window**

- [ ] The announcement went out about two weeks ahead, with a reminder the day before ([#1576](https://github.com/openaustralia/morph/issues/1576)). Window day is Tuesday to Thursday.
- [ ] The people who run the cutover and a second person to review rollback (inferred, no ticket asks for this) are free for the whole window. (Availability is held outside this repository.)
- [ ] Bulk [rsync](https://rsync.samba.org) of the SQLite files and scraper repositories has been repeated recently, and the `log_lines` archive is in S3 ([#1569](https://github.com/openaustralia/morph/issues/1569)). The bulk copy goes into the [data directory](#terms), which every stage links to, so there is no second copy under `/srv/www/production/shared` ([#1579](https://github.com/openaustralia/morph/issues/1579) as amended). The roles create the data directory and the links in each stage's `shared/db/scrapers` (from #1579, not verified here).
- [ ] Certificates are issued on the new server for `morph.io`, `www`, `api`, `faye`, `help` and `discuss` ([#1573](https://github.com/openaustralia/morph/issues/1573)).
- [ ] The Terraform merge request that points the `morph.io` A record at the new instance is written and reviewed, not applied ([#1573](https://github.com/openaustralia/morph/issues/1573)). Every other name is a CNAME to `morph.io` and the TTL is already 300 seconds, so no TTL lowering is needed (from #1573, read 2026-10-20). Re-check the TTL on the day.
- [ ] A second Terraform merge request that reverts that change is written and reviewed, and **kept unmerged** ([#1579](https://github.com/openaustralia/morph/issues/1579)). Rollback until the site opens is merging and applying this merge request.
- [ ] Elastic's support matrix has been rechecked for Ubuntu 26.04, with the Docker fallback ready if it still does not list it ([#1569](https://github.com/openaustralia/morph/issues/1569), third comment).
- [ ] The human-only access is in place: Linode and its API token, the Cloudflare token for certificates, the GitHub App callback URL, Sentry production DSN, restic storage credentials ([#1577](https://github.com/openaustralia/morph/issues/1577)). Credentials stay in the vault. The production restic repository and credentials are used only from cutover night and are not installed on the rehearsal stage.
- [ ] A test GitHub account and test scrapers exist for the smoke test ([#1567](https://github.com/openaustralia/morph/issues/1567)).
- [ ] The cutover merge is prepared and **not merged**: a branch cut from `feature/1579-new-server` that removes Honeybadger and adds `config/deploy/production.rb` naming the new Linode by its own fixed hostname (never `morph.io`), as a pull request into `main` with CI green ([step 2](#2-cutover-merge-and-first-production-deploy)). Neither `main` nor the branch has a production stage before it merges. How the stage file travels with the merge is inferred from that rule.

## Sequence at a glance

| Step | What happens | Rollback point |
| --- | --- | --- |
| 1 | Window opens after the 10:00 AEDT cron; read-only mode on, old cron off, queue drained | R1 |
| 2 | Cutover merge, then the first `production` deploy to `/srv/www/production` | R0 |
| 3 | Discourse read-only; final SQLite delta, filtered MySQL dump and load, Discourse restore, reindex, migrations, production settings | R1 |
| 4 | Smoke test the new server through a hosts override | R1 |
| 5 | Terraform DNS flip, still read-only | R2 |
| 6 | Open the site, turn cron on at the new server, run `auto_run_scrapers` once, Discourse out of read-only mode | R3 (point of no return) |
| 7 | Retire the rehearsal stage once the site is open and stable | none |
| 8 | After the window: power off the old server, backfill, backups, decommission | none |

## In the window

The window starts after the 10:00 AEDT cron has run ([#1573](https://github.com/openaustralia/morph/issues/1573)). Keep a written log with a time against each step (inferred, no ticket asks for this). The log feeds the next retrospective and the "finished" post.

### 1. Freeze the old server

Action, in this order:

1. Turn on read-only mode, from the **Go into site-wide read-only mode** button on the admin dashboard ([`app/admin/dashboard.rb`](../../app/admin/dashboard.rb), verified), or `SiteSetting.toggle_read_only_mode!` in a Rails console (verified to exist).
2. Turn `cron_enabled` off on the old server and re-run its provisioning, or otherwise disable its cron entries (from #1567; the exact mechanism on the old server is not in this repository). This stops `auto_run_scrapers`, `send_alerts` and `stop_long_running_scrapers`.
3. Drain the `scraper` queue: wait for queued and running jobs to finish. `ScraperAutoRunWorker` runs on the `default` queue and is scheduled up to 24 hours ahead, so also expect scheduled jobs. Under read-only mode they raise and land in the retry set, which is discarded and not carried across (from #1573), and which may show as Sentry or Sidekiq errors during the window. Queues are `default` and `scraper` (verified in [`config/sidekiq.yml`](../../config/sidekiq.yml)), and the [Sidekiq](https://sidekiq.org) dashboard is mounted at `/admin/jobs` (verified in [`config/routes.rb`](../../config/routes.rb)).
4. Let running containers finish, or stop them, and resolve any Run whose job is in the scheduled or retry set. Redis is not carried across but the Run rows are, and `Scraper#runnable?` is false while a scraper's last Run is unfinished (verified in [`app/models/scraper.rb`](../../app/models/scraper.rb)), so a leftover unfinished Run would block that scraper's manual and automatic runs on the new server (inferred from the code, not tested). Do this before the final dump in step 3. List containers with `Morph::DockerUtils.running_containers` in a console (verified) or `docker ps`.
5. Stop the workers.
6. Post the pinned forum topic's "started" update, using the approved text, before the forum restore in step 3 ([#1576](https://github.com/openaustralia/morph/issues/1576)).

Do **not** touch or flush the old server's Redis. It holds the schedule that rollback restores ([#1573](https://github.com/openaustralia/morph/issues/1573)).

Check: the banner shows to a signed-out visitor (this depends on the layout change in the gates); no scraper containers are running; no unfinished Runs remain (`Morph::Emergency.find_all_unfinished_runs_attached_to_scrapers` in a console returns nothing, verified to exist in [`app/lib/morph/emergency.rb`](../../app/lib/morph/emergency.rb)); the `scraper` queue is empty; a test sign-in is refused (this depends on the sign-up change in the gates); no cron job fired in the last few minutes.

Rollback point R1: turn read-only mode off, turn the old server's `cron_enabled` back on, restart workers. No DNS change is needed because DNS has not moved. Post a "change of plan" note on the forum.

### 2. Cutover merge and first production deploy

Settled in review: the cutover merge lands at the **start of the window**, after the 10:00 AEDT cron, and the first `production` deploy runs straight after it. No `production` stage exists on `main` or on the branch before that merge ([decision](#decisions-settled-while-writing-this-runbook)).

Start this step as soon as read-only mode is on (step 1, action 1). The deploy does not touch the old server, so step 1's drain and this step's deploy run side by side, and step 3 starts when both are finished (inferred, to save window time).

There is no rename of the rehearsal stage. The first `production` deploy goes straight to `/srv/www/production` on the new server ([#1579](https://github.com/openaustralia/morph/issues/1579), [#1595](https://github.com/openaustralia/morph/issues/1595) as amended).

**The production stage file.** `config/deploy/production.rb` names the new Linode by its own fixed hostname, the one that [merge request 922](https://gitlab.com/openaustralia/infrastructure/-/merge_requests/922) in the infrastructure repository creates. It never names `morph.io`, the old server's name or its IP address, so the old server can never receive a production deploy of the Ruby 3.4 code. Merge request 922 and the hostname are not verified here, and the hostname is not written in this public file. Verified on this branch: [`config/deploy/production.rb`](../../config/deploy/production.rb) exists today and hard-codes the old server's IP address. [PR #1615](https://github.com/openaustralia/morph/pull/1615) removes that file from the branch and adds the `rehearsal` stage, so after it merges the file is gone until this step.

**Cost.** A first deploy into an empty stage directory has no cached bundle or compiled assets, so it runs a full `bundle install` and a full asset precompile inside the window. The Capfile requires `capistrano/bundler` and `capistrano/rails/assets` (verified in the `Capfile`), and the deploy also runs `app:update_docker_images` through `deploy:docker` (verified in [`config/deploy.rb`](../../config/deploy.rb)). That time is not measured yet. The dry runs time it, by deploying into an empty stage directory each time (inferred), and it counts against the 4-hour bar.

Action:

1. Merge the prepared cutover branch to `main` (see the gates). It removes Honeybadger and adds the `production` stage file above ([#1574](https://github.com/openaustralia/morph/issues/1574), [#1575](https://github.com/openaustralia/morph/issues/1575)). Verified leftovers on the branch when this runbook was written: the `honeybadger` gem and its comments in the `Gemfile` (and so `Gemfile.lock`), `require "capistrano/honeybadger"` in the `Capfile`, the `HONEYBADGER_API_KEY` lines in `env-example` and `docker-compose.ruby34.yml`, and a comment in `config/initializers/sentry.rb`. There is no Honeybadger initializer or `config/honeybadger.yml`, although #1574 mentions one. Sentry must be the only error tracker from the first day ([#1474](https://github.com/openaustralia/morph/issues/1474)).
2. Provision the production stage: re-run the roles from `openaustralia/infrastructure` with `morph_stage` set to `production`, so the nginx root, systemd units, cron lines (still off) and the `shared` directory point at `/srv/www/production` (from #1595), and `shared/db/scrapers` links to the [data directory](#terms). The restic source for the SQLite data should be the data directory itself, not a stage path, so retiring a stage cannot drop it from backups (inferred). Whether this replaces or sits beside the rehearsal stage's units is not checkable here.
3. Run the first deploy: `cap production deploy`, which writes to `/srv/www/production`. Capistrano's `deploy_to` is set to `/var/www` in `config/deploy.rb` on this branch (verified), so the per-stage `deploy_to` from [#1595](https://github.com/openaustralia/morph/issues/1595) must be in the merged code, or the release lands in the wrong directory. The deploy also runs migrations (`capistrano/rails/migrations`, verified in the `Capfile`), restarts `morph.target` (`foreman:restart`) and then runs `app:emergency:fix_queue_run_inconsistencies`, which re-queues unfinished Runs (verified in `config/deploy.rb`). At this point the new server's database holds whatever the last dry run left, not the final data.
4. Stop services on the new server again straight after the deploy, and clear its Redis, so nothing the deploy queued runs against the old data (inferred). Services stay stopped until the end of step 3.

Check:

- The stage file names the new Linode's own hostname and does **not** name `morph.io`, the old server or an IP address: its `role` lines contain none of those. Check this **before** the deploy runs, for example by reading the file after the merge and searching it for `morph.io` and for any dotted-number address (nothing should match).
- `cap production deploy` connected to the new Linode, not the old server: the deploy's host line shows the new hostname, and the old server's release directory is unchanged.
- `current`, `releases` and `shared` exist under `/srv/www/production`; `shared/db/scrapers` is a link to the data directory (`readlink` shows it) and the deploy did not replace it with an empty directory (Capistrano only creates the shared directory if it is missing, which is inferred and not tested, so confirm it in a dry run); the app starts under the production stage and then services are stopped again. Record the elapsed time of the deploy separately.
- CI passed on the cutover branch, run as CI runs it, with all three skip variables set as in [`.github/workflows/ruby.yml`](../../.github/workflows/ruby.yml) (see [AGENTS.md](../../AGENTS.md)), and a search for `honeybadger` shows no leftovers.

Rollback point R0: revert the merge on `main`, and abandon the new server's production release. The old server is untouched and keeps the code it already has. After the merge `main` can no longer be deployed to the old server, because its ceiling is Ruby 3.0.7 ([ADR 0005](../adr/0005-ruby-3-4-only-on-the-new-server.md)), so a hotfix to the old server after this point needs a separate path.

### 3. Final data move and production settings

Action:

1. Put Discourse in read-only mode as the final dump starts ([#1579](https://github.com/openaustralia/morph/issues/1579)). Use Discourse's own read-only mode. The mechanism is not verified here, so take it from the dry-run log.
2. Stop the rehearsal stage's services on the new server, so nothing else writes while data moves (inferred).
3. Run the final SQLite and scraper repository delta from the old server ([#1569](https://github.com/openaustralia/morph/issues/1569)). The target is the [data directory](#terms), the same one the bulk copy filled, so the delta only adds what changed and nothing is copied again. It should be short, because few `data.sqlite` files change in a week (from #1569).
4. Take the filtered MySQL dump of the retained `log_lines` plus all other tables and load it into MySQL 8.4 with `utf8mb4_unicode_ci` ([#1569](https://github.com/openaustralia/morph/issues/1569), [#1571](https://github.com/openaustralia/morph/issues/1571)). Production's `log_lines` is never modified, so the old server stays a complete fallback. Do **not** run the scrub on this restore: it is for dry-run restores only, and the cutover restore keeps real data. In the dry runs the scrub covers emails, tokens and webhook URLs ([#1567](https://github.com/openaustralia/morph/issues/1567)), scraper secret variables and suppressed email addresses ([#1579](https://github.com/openaustralia/morph/issues/1579)), and, from the 2026-11-27 amendments, `email_suppressions.reply_excerpt` (replaced with fixed placeholder text) and every IP address column (replaced with an address from a documentation range, such as `192.0.2.1` or `2001:db8::1`). Verified IP address columns in [`db/schema.rb`](../../db/schema.rb) on this branch: `owners.current_sign_in_ip`, `owners.last_sign_in_ip` and `runs.ip_address`, plus `email_suppressions.reply_excerpt`. The scrub must cover every such column, so re-check the schema when the script is written.
5. Take a fresh Discourse backup, now final, and restore it on the new server. The hostname must be `help.morph.io` and the DiscourseConnect URL and secret must point at `morph.io`, not at the rehearsal names (inferred from #1567, which described the remap the other way for rehearsal and flagged it as unverified). Keep the restored Discourse in read-only mode until step 6 (inferred: a restore may not carry the read-only state across, so check it).
6. Reindex Elasticsearch from the loaded database. The index is rebuilt, never migrated ([#1569](https://github.com/openaustralia/morph/issues/1569), [#1572](https://github.com/openaustralia/morph/issues/1572)). [Searchkick](https://github.com/ankane/searchkick) is used, and the cron entry `searchkick:reindex:all` is named in #1567. The reindex command itself is not defined in this repository's rake files, so copy it from the dry-run log.
7. Do **not** start Redis state from the old server. The new server starts with empty Redis ([#1569](https://github.com/openaustralia/morph/issues/1569)). Clear the new server's Redis if the rehearsal stage left anything in it (inferred).

8. Run the pending migrations on the loaded data, because the load brings in the old schema, for example `cap production deploy:migrate` (a task from `capistrano/rails/migrations`, which the Capfile requires, verified) or `bundle exec rake db:migrate` in the release (inferred). It does nothing if the schema already matches.
9. Install the production-only settings that the rehearsal stage never held: Postal credentials ([#1573](https://github.com/openaustralia/morph/issues/1573)), the Sentry production DSN ([#1574](https://github.com/openaustralia/morph/issues/1574)), and the production restic credentials ([#1579](https://github.com/openaustralia/morph/issues/1579)). The production restic repository and credentials exist only from cutover night, so the pre-cutover drill never touched them. The restic job and the other scheduled jobs stay off until step 6, because `cron_enabled` is still off (inferred ordering).
10. Remove the help.morph.io redirect: delete `discourse_maintenance_redirect_url` from the infrastructure repository's production `group_vars` and re-run the roles, so `help.morph.io` serves Discourse again ([#1579](https://github.com/openaustralia/morph/issues/1579)). The variable lives outside this repository, so it is not verified here.
11. Start services on the new server, now with the production settings installed, so the smoke test in step 4 runs against the final configuration (inferred ordering). Cron stays off.

Check, recorded against the dry-run numbers ([#1579](https://github.com/openaustralia/morph/issues/1579), data-migration verification): MySQL row counts and checksums, SQLite file counts and sizes, Elasticsearch document counts. Discourse is in read-only mode on both servers; no migration is pending; `help.morph.io`, when overridden to the new server, serves Discourse and not a redirect; the restic and other scheduled jobs have not run. Record the elapsed time of this whole step.

Go/no-go checkpoint (inferred): if the elapsed time is on course to overrun the announced window, stop here and use R1.

Rollback point R1: wipe nothing on the old server. Restore the redirect variable and re-run the roles if you reach R2 after removing it. Take Discourse on the old server out of read-only mode as part of R1. Abandon the new server's loaded data, because it can be re-synced for another attempt.

### 4. Smoke test the new server

Action: run the checklist in `docs/rehearsal-smoke-test.md` against the production stage on the new server, with the site **read-only**. Point every name the test uses at the new server from the tester's own machine only, with hosts-file entries or `curl --resolve`: `morph.io`, `www`, `api`, `faye` and `help` (and `discuss` if used). They are CNAMEs to `morph.io` in DNS, so a hosts entry for `morph.io` alone does not move them, and live log streaming (`faye`) and Discourse (`help`) would otherwise test the old server ([#1573](https://github.com/openaustralia/morph/issues/1573)). That checklist was written for the rehearsal hostname behind basic auth, so substitute the production names and ignore the basic-auth steps (inferred). At cutover also check:

1. A real email sent through Postal reaches a maintainer.
2. Discourse shows topics and accounts, and signing in through DiscourseConnect lands on `morph.io`.
3. Certificates are the production ones for every name above.

**The one documented exception.** Starting a run is refused while read-only mode is on: the API run endpoint returns "You currently can't start a scraper run" in that mode (verified in [`app/controllers/api_controller.rb`](../../app/controllers/api_controller.rb), `can_run`). To run the throwaway test scraper, switch read-only mode off on the new server, run that one scraper and watch live log streaming, then switch read-only mode back on. Only the tester's hosts override reaches the new server at this point. Whether a run can start under read-only on the new server is untested, so settle the exact method in a dry run. Cron stays off throughout.

Check: every item passes. Then delete the test scraper and the test account's leftovers, switch read-only mode back on, and **verify it before step 5** with the banner on a signed-out request through the same hosts override and a refused test sign-in (this depends on the sign-up change). Any failure is a no-go.

Rollback point R1: this is the last cheap exit. Nothing public has changed ([#1573](https://github.com/openaustralia/morph/issues/1573)).

### 5. Flip DNS with Terraform

Action: apply the reviewed `morph.io` A record merge request in `openaustralia/infrastructure`, with the site still read-only and cron still off ([#1573](https://github.com/openaustralia/morph/issues/1573)). Follow that repository's GitLab process for applying Terraform; the apply mechanism is not described in this repository.

Check:

- `dig` against a public resolver returns the new address for `morph.io`, and the names that are CNAMEs follow it. TTL is 300 seconds, so allow a few minutes (from #1573).
- Read-only mode is on at the new server before and after the flip (the banner shows to a signed-out visitor).
- Public checks: `https://morph.io` loads and serves the read-only banner, `https://api.morph.io` responds, `https://help.morph.io` loads, live log streaming through `faye.morph.io` connects.
- The old server stops receiving new page requests (check its nginx log).

Rollback point R2: **merge and apply the prepared revert merge request**. DNS flips back within the TTL. Then turn read-only mode off and the old server's `cron_enabled` back on, restart workers there, take Discourse on the old server out of read-only mode and restore the `help.morph.io` redirect if step 3 removed it. Nothing was written on the old server after the final dump, and the only writes on the new server are deleted smoke-test leftovers, so no data is lost, provided the sign-up refusal was in place ([#1573](https://github.com/openaustralia/morph/issues/1573)). The old server's Redis still holds its schedule. Post a "change of plan" note on the forum.

### 6. Open the site

Action, in this order:

1. Turn read-only mode off on the new server.
2. Turn `cron_enabled` on for the **new** server only. The check in `site.yml` refuses to run if more than one morph host has it on ([#1567](https://github.com/openaustralia/morph/issues/1567)), so the old server's flag must already be off. This also lets the production restic job and the nightly dump run that night.
3. Run `auto_run_scrapers` once on the new server as the application user, in the production Rails environment. The task is `app:auto_run_scrapers`, defined in [`lib/tasks/app.rake`](../../lib/tasks/app.rake) (verified). It queues every scraper with `auto_run` set, spread over the next 24 hours, and prints `Queued N scrapers to run over the next 24 hours`. Copy the exact invocation from the cron line the roles install, because that is not in this repository.
4. Take Discourse out of read-only mode ([#1579](https://github.com/openaustralia/morph/issues/1579)).
5. Post the "finished" follow-up on the forum ([#1576](https://github.com/openaustralia/morph/issues/1576)).

Check:

- The admin dashboard shows read-only mode off; a signed-in test person can create a scraper.
- `auto_run_scrapers` printed a count close to the number of scrapers with auto run on.
- The first scheduled runs start, finish, and their log lines stream live.
- A new post can be made on `help.morph.io`.
- Sentry receives events from the new server, and its uptime check on `morph.io` and `help.morph.io` is green ([#1574](https://github.com/openaustralia/morph/issues/1574)).
- The new server's Sidekiq shows no growing retry set.

**Rollback point R3 is the point of no return.** From here the site is roll-forward only. There is no reverse sync from the new server to the old one ([#1573](https://github.com/openaustralia/morph/issues/1573)). Do not run this step until every check in steps 4 and 5 passed.

What to expect after opening ([#1573](https://github.com/openaustralia/morph/issues/1573)):

- Most of the old server's day of scheduled runs is waiting in its Redis and never moves, so running the task once replaces that schedule straight away.
- The 10:00 cron the next morning queues another cycle, so for a few hours some scrapers get two runs close together. The concurrent-scraper cap absorbs it (unverified how mild this is).
- Jobs that came due during the window raised in `ScraperAutoRunWorker` and went to the old server's retry set, which is not carried across. The one `auto_run_scrapers` run covers them.

### 7. Retire the rehearsal stage

The rehearsal stage and its names, basic auth, mail sink and switches are retired from the new Linode at cutover ([#1579](https://github.com/openaustralia/morph/issues/1579)). Do this once the site is open and stable. Stable means the morning-after checks in step 8 have passed (inferred, no ticket defines it). It does not need to happen inside the window.

Action ([#1573](https://github.com/openaustralia/morph/issues/1573), [#1567](https://github.com/openaustralia/morph/issues/1567)):

1. Remove the `new.morph.io` and `new-help.morph.io` records and their certificates, through a merge request in the infrastructure repository.
2. Remove nginx basic auth from the new Linode.
3. Remove the mail sink. The playbook fails if a production host is configured to send mail to the sink (from #1579), so confirm production mail still goes through Postal.
4. Remove the rehearsal switches: the rehearsal-only settings in the roles and the `rehearsal` stage's host settings, so that no host is left that could run as the rehearsal stage.
5. Remove the extra GitHub App callback URL that was added for rehearsal.
6. Confirm no data scrub script is scheduled against production. The scrub was only for dry-run restores and is excluded from cutover (from #1567).
7. Remove the rehearsal stage's own directory, `/srv/www/rehearsal`, once nothing refers to it (inferred, the tickets list the names, basic auth, mail sink and switches only). It must **not** delete the [data directory](#terms). First confirm with `readlink` that the stage's `shared/db/scrapers` is a link to the data directory, then remove the link and the stage directory without following the link (inferred handling). The data is not copied back or twice, and nothing in the production stage depends on the rehearsal directory.
8. Set reverse DNS for the new address, if Linode needs the forward record to match first. #1573 did not verify that ordering, and it matters little because mail goes through Postal.

Check: the SQLite file count and total size in the data directory are the same before and after the removal, and `current/db/scrapers` in the production stage still resolves to it; `new.morph.io` and `new-help.morph.io` no longer resolve; a request to the old basic-auth path gets no challenge; no mail sink process or port is running; signing in through GitHub still works; the callback URL list contains only production's; a test email still leaves through Postal.

No rollback point: these are clean-ups and each is reversible by redoing it, but they are not part of rollback.

## After the window

### 8. Power off, backfill, back up and decommission

**Power off the old server** ([#1579](https://github.com/openaustralia/morph/issues/1579))

Action: once step 6 has passed, power off the old Linode in Linode's manager. Do not do this earlier, because R2 needs it running (inferred: the tickets say powered off for both periods but not the moment).

Check: the old server no longer answers, and `morph.io` and `help.morph.io` are unaffected.

**Backfill the archived `log_lines`** ([#1601](https://github.com/openaustralia/morph/issues/1601))

Action:

1. Before loading, check that the new server's `log_lines` auto-increment value starts above production's highest id at dump time, so new rows cannot collide with archived rows ([map](https://github.com/openaustralia/morph/issues/1557), "Not yet specified"). If it does not, raise it first.
2. Run the archive load with `loadDdl: false` at a low thread count in nightly off-peak slots, stopped by morning (from #1601; the option names come from [MySQL Shell](https://dev.mysql.com/doc/mysql-shell/8.4/en/) docs, not a run).
3. Raise the throttle if it is not done within 3 weeks.

Check: the loaded row count equals the archive's recorded count with overlap counted once; a sample of old runs shows their log lines; a re-run changes nothing. Until then, old runs show no log lines, which the announcement says.

**First nightly dump and backup** ([#1574](https://github.com/openaustralia/morph/issues/1574))

Action: watch only, no change, on the morning after opening. The production restic credentials were installed in step 3 and `cron_enabled` went on in step 6, so the first nightly dump and the restic backup after it run that night.

Check:

- The nightly dump (`mysqldump | zstd`) ran, and the [restic](https://restic.net) job ran after it, so it uploaded that night's dump.
- Sentry cron monitors reported for `auto_run_scrapers`, `send_alerts`, `stop_long_running_scrapers`, the dump and the backup.
- `send_alerts` (11:30) sent through Postal and none failed.
- `searchkick:reindex:all` (06:00) ran and search still returns scrapers.
- The old `duply` chains under `oaf-backups/morph/` are left untouched until a person deletes them after the new restic repository has proven itself ([#1574](https://github.com/openaustralia/morph/issues/1574)).

**Second restore drill, then drop Linode Backups** ([#1574](https://github.com/openaustralia/morph/issues/1574), [#1579](https://github.com/openaustralia/morph/issues/1579))

Action, within 7 days of cutover: run a second drill, this time against the **production** restic repository. The first drill, before cutover, used a throwaway repository ([gates](#go-and-no-go-gates-before-the-window)). Restore a sample of SQLite files and the latest MySQL dump from restic to a scratch location, load the dump into a scratch MySQL, and compare row counts. Only after it passes, switch off Linode Backups on the new Linode. (Reading of "before Linode Backups is dropped": Linode Backups stays on for the new Linode until the drill passes. Inferred.)

Check: the restic repository used is the production one, the restored files open, the row counts match production's, and Linode Backups is off only after that. If the drill fails, leave Linode Backups on and fix restic first.

**Decommission the old server** ([#1573](https://github.com/openaustralia/morph/issues/1573), [#1579](https://github.com/openaustralia/morph/issues/1579))

The old Linode is powered off for both 14-day periods: 14 days as the rollback path, then 14 more before deletion. The clock starts when it is powered off. Dates are counted from there, not fixed here.

| Stage | Length | State | Action | Check before moving on |
| --- | --- | --- | --- | --- |
| A | 14 days | Powered off, as the rollback path | Leave it off. If something must be recovered, power it on, copy what is needed, and power it off again | No complaint or data gap needs the old server; the restore drill has passed |
| B | a further 14 days | Powered off | Leave it off; at day 28 open the deletion merge request (below) | Nothing has needed it; the `log_lines` backfill is complete |
| C | day 28 | Deleted | Apply the deletion merge request | The plan shows only the old resources |

Action for stage C, through a GitLab merge request in `openaustralia/infrastructure`:

1. Delete the old instance and its Linode Backups, and its Terraform resources `linode_instance.main` and `linode_rdns.main` (from #1573). Never rename `main`: a rename would replace the live server. Confirm which instance is which before applying.
2. Remove the S3 `log_lines` archive, which is kept until the old Linode is deleted ([#1601](https://github.com/openaustralia/morph/issues/1601)).
3. Delete `provisioning/`, the `Vagrantfile` and the Makefile Ansible targets from this repository ([#1566](https://github.com/openaustralia/morph/issues/1566), [ADR 0002](../adr/0002-provision-the-new-server-from-the-infrastructure-repository.md)). Decide at the same time whether the old `iptables-morph-*` files go or stay for #1506 ([#1600](https://github.com/openaustralia/morph/issues/1600)).
4. Close #1579 and the map.

Check: the Terraform plan shows only the old instance, its rDNS record and its backups being destroyed, and nothing for the new instance.

No rollback after stage C.

## Rollback

Rollback is a Terraform revert once DNS has moved (R2), and an undo of the freeze before that (R1), and it is possible **only until the site opens**. After that it is roll-forward only, and the powered-off old server is a recovery source, not a way back.

| Point | Reached at | How to roll back | What it costs |
| --- | --- | --- | --- |
| R0 | Step 2 | Revert the merge on `main`; abandon the new server's production release | Nothing public changed |
| R1 | Steps 1, 3 and 4 | Read-only mode off; old `cron_enabled` on; restart workers on the old server; Discourse on the old server out of read-only mode. No DNS change | Time lost; announce a change of plan |
| R2 | Step 5, before opening | Merge and apply the prepared revert merge request; then as R1, and restore the help.morph.io redirect if step 3 removed it | DNS propagation within the TTL |
| R3 | Step 6 onward | None. Fix forward on the new server | Writes made on the new server since opening exist only there; no reverse sync |

Triggers (inferred, to confirm in a dry run): any failed smoke-test item, a data check that does not match, a missing certificate, or a projected overrun of the announced window before step 6. After step 6, a failure is a fix-forward incident, not a rollback.

## Status of claims in this runbook

Read on 2026-11-27 against `feature/1579-new-server` and the branch of PR #1615 at the time of writing.

**Verified in this repository**

- `SiteSetting.read_only_mode` and `toggle_read_only_mode!` exist, the admin dashboard has the toggle button, and abilities and `ScraperAutoRunWorker` honour it.
- Read-only mode does not refuse sign-ups: `User.find_for_github_oauth` creates or updates a user and no controller other than the API run endpoint checks it. The change to refuse them is not built.
- The read-only notice is only shown to signed-in people (layout change on `main` still outstanding).
- `app:auto_run_scrapers`, `app:send_alerts` and `app:stop_long_running_scrapers` are defined in `lib/tasks/app.rake`, and `auto_run_scrapers` queues over 24 hours.
- Sidekiq queues are `default` and `scraper`, and the Sidekiq dashboard is mounted at `/admin/jobs`.
- `honeybadger` is still in the `Gemfile` and `require "capistrano/honeybadger"` is still in the `Capfile`.
- The `Capfile` requires `capistrano/bundler`, `capistrano/rails/assets` and `capistrano/rails/migrations`, and `config/deploy.rb` runs `deploy:docker`, `foreman:restart` and the queue fix after a deploy, and sets `deploy_to` to `/var/www`.
- `db/schema.rb` has the IP address columns `owners.current_sign_in_ip`, `owners.last_sign_in_ip` and `runs.ip_address`, and `email_suppressions.reply_excerpt`.
- `config/deploy/production.rb` exists on this branch and hard-codes an IP address. The branch of PR #1615 removes it, adds `config/deploy/rehearsal.rb` and carries `docs/rehearsal-smoke-test.md`.

**Not checkable here (infrastructure repository, Terraform, accounts, Discourse)**

- `cron_enabled`, `morph_stage`, `discourse_maintenance_redirect_url`, certificate issuing, the Terraform records and merge requests, the cron lines, and the `site.yml` guard.
- How Discourse's read-only mode is switched on, and whether a restore carries it across.
- The exact commands for the reindex, the dump and load, the rsync delta and the Terraform apply. Take them from the dry-run log.

**Inferred by this runbook**

- How the production stage file travels with the cutover merge, running the deploy beside step 1's drain, the order of the steps inside step 3, the go/no-go checkpoints, restic credentials installed before `cron_enabled`, the Discourse hostname at cutover, when the old server is powered off, what "stable" means for retiring the rehearsal stage, the reading of "before Linode Backups is dropped", how the dry runs time the first deploy, the throwaway restic repository's location and clean-up, the restic source being the data directory, and how the rehearsal directory is removed without touching the data directory.

## Decisions settled while writing this runbook

- **Production stage file and merge timing.** The `production` Capistrano stage file names the new Linode by its own fixed hostname, the one [merge request 922](https://gitlab.com/openaustralia/infrastructure/-/merge_requests/922) in the infrastructure repository creates, and never names `morph.io`, so the old server can never receive a production deploy of the Ruby 3.4 code. The cutover merge lands at the start of the window, after the 10:00 AEDT cron, and the first production deploy runs straight after it. No production stage exists before that merge. Settled in review of this runbook, to be recorded in the spec [#1579](https://github.com/openaustralia/morph/issues/1579).

The other decisions that shape this runbook are in the amendments to [#1579](https://github.com/openaustralia/morph/issues/1579) and [#1573](https://github.com/openaustralia/morph/issues/1573) dated 2026-11-27.

There are no open questions left.
