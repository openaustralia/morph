# Cutover runbook: move morph.io to the new server

This runbook is the step-by-step plan for the day morph.io and help.morph.io move from the Ubuntu 16.04 Linode (the old server) to the Ubuntu 26.04 Linode (the new server). It is written for #1592, part of the spec in #1579.

It links to the decisions instead of restating them. The map [#1557](https://github.com/openaustralia/morph/issues/1557) lists every closed decision ticket. Where a closed ticket holds more detail than this file, the closed ticket wins, and this file is what needs fixing.

## How to read this runbook

Every step has an **Action** (what to do, with no one named) and a **Check** (what proves it worked). Steps that can be undone say where. Four rollback points, R0 to R3, are marked in the sequence, and the [rollback section](#rollback) says what each one costs.

Claims are marked so nobody mistakes a guess for a fact:

- **Verified** means checked against this repository on the date in the [status section](#status-of-claims-in-this-runbook).
- **From #NNNN** means taken from a closed decision ticket and not checkable from this repository, because it lives in the `openaustralia/infrastructure` repository (on GitLab), in [Terraform](https://developer.hashicorp.com/terraform) or in a person's account.
- **Inferred** means this runbook joined the dots and no ticket says it. Confirm it in a dry run.

Public repository rules apply. Do not put credentials, IP addresses, the announcement text or anyone's name or availability in this file. The new scraper IP address goes in the announcement, which is approved separately and is not committed ([#1576](https://github.com/openaustralia/morph/issues/1576)).

## Terms

- **Window**: the announced maintenance period. It starts after the 10:00 AEDT cron and runs for the second dry run's measured time plus 50% ([#1576](https://github.com/openaustralia/morph/issues/1576)).
- **Read-only mode**: `SiteSetting.read_only_mode`. It blocks people from creating, editing or deleting scrapers and from resetting API keys. It does **not** stop scraper runs that are already queued or running, which is why the freeze also turns cron off and drains the queue ([#1569](https://github.com/openaustralia/morph/issues/1569)). Verified in [`app/models/site_setting.rb`](../../app/models/site_setting.rb), `app/abilities/` and [`app/workers/scraper_auto_run_worker.rb`](../../app/workers/scraper_auto_run_worker.rb).
- **Smoke test**: the end-to-end checklist in [#1579](https://github.com/openaustralia/morph/issues/1579) (sign in through the GitHub App, run a test scraper, watch live log streaming, fetch data through the API, search, check the admin area), plus Discourse and a real email ([#1573](https://github.com/openaustralia/morph/issues/1573)).
- **New server** is the glossary's **Rehearsal server** ([GLOSSARY.md](../../GLOSSARY.md), which lists "new server" under _Avoid_). This runbook keeps "new server" because the decision tickets and the spec use it for the cutover target. It is the same machine that becomes production at the stage rename in step 2, which is why the decision tickets and this runbook say "new server" throughout.

## Go and no-go gates before the window

Do not announce a date until the first group is true, and do not start the window until all of them are true. Each is a check, not a step.

**Before announcing**

- [ ] The second full dry run finished every in-window step in 4 hours or less ([#1569](https://github.com/openaustralia/morph/issues/1569)).
- [ ] The [restic](https://restic.net) restore drill passed on the rehearsal server: a sample of SQLite files and the latest MySQL dump restored, the dump loaded, row counts checked ([#1574](https://github.com/openaustralia/morph/issues/1574)).
- [ ] The Discourse trial restore passed ([#1563](https://github.com/openaustralia/morph/issues/1563), [#1569](https://github.com/openaustralia/morph/issues/1569)).
- [ ] The full `log_lines` archive restored on the rehearsal server and a re-run of the load changed nothing ([#1601](https://github.com/openaustralia/morph/issues/1601)).
- [ ] The rehearsal checks in [#1600](https://github.com/openaustralia/morph/issues/1600) passed, including the container-to-host exposure check that decision left open.
- [ ] The layout change on `main` that shows the read-only notice to **all** visitors has landed ([#1576](https://github.com/openaustralia/morph/issues/1576)). Verified as still outstanding when this runbook was written: [`app/views/layouts/application.html.haml`](../../app/views/layouts/application.html.haml) shows the notice only when `signed_in? && SiteSetting.read_only_mode`.
- [ ] The announcement text is approved, with the date, window length and new scraper address in it ([#1576](https://github.com/openaustralia/morph/issues/1576)). Not committed here.

**Before the window**

- [ ] The announcement went out about two weeks ahead, with a reminder the day before ([#1576](https://github.com/openaustralia/morph/issues/1576)). Window day is Tuesday to Thursday.
- [ ] The people who run the cutover and a second person to review rollback (inferred, no ticket asks for this) are free for the whole window. (Availability is held outside this repository.)
- [ ] Bulk [rsync](https://rsync.samba.org) of the SQLite files and scraper repositories has been repeated recently, and the `log_lines` archive is in S3 ([#1569](https://github.com/openaustralia/morph/issues/1569)).
- [ ] Certificates are issued on the new server for `morph.io`, `www`, `api`, `faye`, `help` and `discuss` ([#1573](https://github.com/openaustralia/morph/issues/1573)).
- [ ] The Terraform merge request that points the `morph.io` A record at the new instance is written and reviewed, not applied ([#1573](https://github.com/openaustralia/morph/issues/1573)). Every other name is a CNAME to `morph.io` and the TTL is already 300 seconds, so no TTL lowering is needed (from #1573, read 2026-10-20). Re-check the TTL on the day.
- [ ] A second Terraform merge request that reverts that change is written and reviewed, so rollback is one action (inferred).
- [ ] Elastic's support matrix has been rechecked for Ubuntu 26.04, with the Docker fallback ready if it still does not list it ([#1569](https://github.com/openaustralia/morph/issues/1569), third comment).
- [ ] The human-only access is in place: Linode and its API token, the Cloudflare token for certificates, the GitHub App callback URL, Sentry production DSN, restic storage credentials ([#1577](https://github.com/openaustralia/morph/issues/1577)). Credentials stay in the vault.
- [ ] A test GitHub account and test scrapers exist for the smoke test ([#1567](https://github.com/openaustralia/morph/issues/1567)).
- [ ] The Honeybadger removal and the cutover changes to deploy configuration are ready to merge ([step P1](#p1-merge-the-new-stack-to-main)).

## Sequence at a glance

| Step | What happens | Rollback point |
| --- | --- | --- |
| P1 | Merge `feature/1579-new-server` to `main` | R0 |
| 1 | Window opens after the 10:00 AEDT cron; read-only mode on, old cron off, queue drained | R1 |
| 2 | Services stopped on the new server; stage rename and redeploy on the new server | R1 |
| 3 | Final SQLite delta, filtered MySQL dump and load, Discourse restore, reindex, production-only secrets | R1 |
| 4 | Smoke test the new server through a hosts override | R1 |
| 5 | Terraform DNS flip, still read-only | R2 |
| 6 | Open the site, turn cron on at the new server, run `auto_run_scrapers` once | R3 (point of no return) |
| 7 | Undo the rehearsal safeguards | none |
| 8 | Backfill `log_lines`, watch, decommission | none |

## Before the window

### P1. Merge the new stack to main

The placement of this step is inferred. See [open question 2](#open-questions).

Action: merge `feature/1579-new-server` to `main` once the rehearsal server has validated it. In the same merge or the commit straight after it:

- Remove Honeybadger ([#1574](https://github.com/openaustralia/morph/issues/1574), [#1575](https://github.com/openaustralia/morph/issues/1575)). Verified leftovers on the branch when this runbook was written: the `honeybadger` gem and its comments in the `Gemfile` (and so `Gemfile.lock`), `require "capistrano/honeybadger"` in the `Capfile`, the `HONEYBADGER_API_KEY` lines in `env-example` and `docker-compose.ruby34.yml`, and a comment in `config/initializers/sentry.rb`. There is no Honeybadger initializer or `config/honeybadger.yml`, although #1574 mentions one. Search for `honeybadger` again before merging, because Sentry must be the only error tracker from the first day ([#1474](https://github.com/openaustralia/morph/issues/1474)).
- Replace the contents of `config/deploy/production.rb` so it points at `morph.io` by hostname, not an IP address ([#1575](https://github.com/openaustralia/morph/issues/1575)). Verified that the file exists on the branch and hard-codes the old server's IP address. Until DNS flips in step 5, `morph.io` still resolves to the **old** server, so a stray `cap production deploy` between this merge and step 5 would push Ruby 3.4 code onto it. #1575 removed the production stage from the branch to prevent exactly that, so see [open question 2](#open-questions) before deciding when this lands.

Check: CI passes on the merge commit, run as CI runs it, with all three skip variables set as in [`.github/workflows/ruby.yml`](../../.github/workflows/ruby.yml) (see [AGENTS.md](../../AGENTS.md)). `bundle exec cap -T` and a search for `honeybadger` show no leftovers.

Rollback point R0: nothing public has changed. Revert the merge if a problem appears. Be aware that after this merge `main` can no longer be deployed to the old server, because its ceiling is Ruby 3.0.7 ([ADR 0005](../adr/0005-ruby-3-4-only-on-the-new-server.md)). The old server keeps running the code it already has, so rollback does not need a redeploy, but a hotfix to the old server after this point needs a separate path. When the merge lands, and what the production stage targets before the flip, are not settled, see [open questions](#open-questions).

## In the window

The window starts after the 10:00 AEDT cron has run ([#1573](https://github.com/openaustralia/morph/issues/1573)). Keep a written log with a time against each step (inferred, no ticket asks for this). The log feeds the next retrospective and the "finished" post.

### 1. Freeze the old server

Action, in this order:

1. Turn on read-only mode, from the **Go into site-wide read-only mode** button on the admin dashboard ([`app/admin/dashboard.rb`](../../app/admin/dashboard.rb), verified), or `SiteSetting.toggle_read_only_mode!` in a Rails console (verified to exist).
2. Turn `cron_enabled` off on the old server and re-run its provisioning, or otherwise disable its cron entries (from #1567; the exact mechanism on the old server is not in this repository). This stops `auto_run_scrapers`, `send_alerts` and `stop_long_running_scrapers`.
3. Drain the `scraper` queue: wait for queued and running jobs to finish. `ScraperAutoRunWorker` runs on the `default` queue and is scheduled up to 24 hours ahead, so also expect scheduled jobs. Under read-only mode they raise and land in the retry set, which is discarded and not carried across (from #1573), and which may show as Sentry or Sidekiq errors during the window. Queues are `default` and `scraper` (verified in [`config/sidekiq.yml`](../../config/sidekiq.yml)), and the [Sidekiq](https://sidekiq.org) dashboard is mounted at `/admin/jobs` (verified in [`config/routes.rb`](../../config/routes.rb)).
4. Let running containers finish, or stop them, and resolve any Run whose job is in the scheduled or retry set. Redis is not carried across but the Run rows are, and `Scraper#runnable?` is false while a scraper's last Run is unfinished (verified in [`app/models/scraper.rb`](../../app/models/scraper.rb)), so a leftover unfinished Run would block that scraper's manual and automatic runs on the new server (inferred from the code, not tested). Do this before the final dump in step 3. List them with `Morph::DockerUtils.running_containers` in a console (verified) or `docker ps`.
5. Stop the workers.
6. Post the pinned forum topic's "started" update, using the approved text, before the forum restore in step 3 ([#1576](https://github.com/openaustralia/morph/issues/1576)).

Do **not** touch or flush the old server's Redis. It holds the schedule that rollback restores ([#1573](https://github.com/openaustralia/morph/issues/1573)).

Check: the banner shows to a signed-out visitor (this depends on the layout change in the gates); no scraper containers are running; no unfinished Runs remain (`Morph::Emergency.find_all_unfinished_runs_attached_to_scrapers` in a console returns nothing, verified to exist in [`app/lib/morph/emergency.rb`](../../app/lib/morph/emergency.rb)); the `scraper` queue is empty; a test sign-in cannot create a scraper; no cron job fired in the last few minutes.

Rollback point R1 (this step to step 4): turn read-only mode off, turn the old server's `cron_enabled` back on, restart workers. No DNS change is needed because DNS has not moved. Post a "change of plan" note on the forum.

### 2. Stop services and rename the stage

Action:

1. Stop app services on the new server so nothing writes while data moves.
2. On the new server, rename `/srv/www/rehearsal` to `/srv/www/production` on the same disk, so the pre-synced SQLite files are never copied again ([#1595](https://github.com/openaustralia/morph/issues/1595)).
3. Set `morph_stage` to `production` and re-run the roles from `openaustralia/infrastructure`, so the nginx root, the systemd units, cron lines and restic sources follow the new path ([#1595](https://github.com/openaustralia/morph/issues/1595)). The rename was rehearsed in both dry runs.
4. Redeploy the release to the `production` stage on the new server, so Capistrano rewrites its symlinks. On this branch `deploy_to` is still `/var/www` in [`config/deploy.rb`](../../config/deploy.rb) (verified), because the lazy per-stage `deploy_to` from [#1595](https://github.com/openaustralia/morph/issues/1595) has not landed, so that change must be in place before this redeploy. Capistrano's `current` link and the links for `linked_dirs` (`db/scrapers`, `public/sitemaps`, `tmp/pids`, `log`) and `linked_files` (verified in [`config/deploy.rb`](../../config/deploy.rb)) are normally absolute paths built from `deploy_to`, so the rename leaves them pointing at `/srv/www/rehearsal` (inferred from how Capistrano works, not tested here; confirm in the dry run). The deploy must reach the new server before DNS flips, so it needs a hosts or ssh override or a server-specific name, not `morph.io` (inferred).
5. Stop services on the new server again. The deploy restarts `morph.target` (`foreman:restart`) and then runs `app:emergency:fix_queue_run_inconsistencies`, which can queue Runs from the data currently loaded (verified in `config/deploy.rb`). Clear the new server's Redis too, so it starts empty as decided in #1569 (inferred). Services stay stopped until the end of step 3.
6. Keep the new server's `cron_enabled` off for now.

Check: `current`, `releases` and `shared` exist under `/srv/www/production`; no path under `/srv/www/rehearsal` remains; every symlink under the release resolves to `/srv/www/production`; `db/scrapers` is the pre-synced data, not an empty directory. #1595 flags as unverified whether any process stores an absolute host path under `shared`, such as scraper container mounts, so check that explicitly.

Rollback point R1: nothing on the old server changed in this step. Undo by renaming back, setting `morph_stage` back and redeploying the `rehearsal` stage if it still exists.

### 3. Final data move

Action:

1. Run the final SQLite and scraper repository delta from the old server into `/srv/www/production/shared/db/scrapers` ([#1569](https://github.com/openaustralia/morph/issues/1569)). It should be short, because few `data.sqlite` files change in a week (from #1569).
2. Take the filtered MySQL dump of the retained `log_lines` plus all other tables, load it into MySQL 8.4 with `utf8mb4_unicode_ci` ([#1569](https://github.com/openaustralia/morph/issues/1569), [#1571](https://github.com/openaustralia/morph/issues/1571)). Production's `log_lines` is never modified, so the old server stays a complete fallback.
3. Take a fresh Discourse backup and restore it on the new server. Whether the old forum is frozen between this backup and the flip is not settled, see open question 6. The hostname must be `help.morph.io` and the DiscourseConnect URL and secret must point at `morph.io`, not at the rehearsal names (inferred from #1567, which described the remap the other way for rehearsal and flagged it as unverified).
4. Reindex Elasticsearch from the loaded database. The index is rebuilt, never migrated ([#1569](https://github.com/openaustralia/morph/issues/1569), [#1572](https://github.com/openaustralia/morph/issues/1572)). [Searchkick](https://github.com/ankane/searchkick) is used, and the cron entry `searchkick:reindex:all` is named in #1567. The reindex command itself is not defined in this repository's rake files, so copy it from the dry-run log.
5. Install the production-only secrets that the rehearsal server never held: Postal credentials ([#1573](https://github.com/openaustralia/morph/issues/1573)), the Sentry production DSN ([#1574](https://github.com/openaustralia/morph/issues/1574)), and the restic credentials (inferred: #1567 says the rehearsal never gets backup credentials, and no ticket says when they arrive, so confirm this is the moment).
6. Do **not** start Redis state from the old server. The new server starts with empty Redis ([#1569](https://github.com/openaustralia/morph/issues/1569)).
7. Start services on the new server, now with the production secrets installed, so the smoke test in step 4 runs against the final configuration (inferred ordering). Cron stays off.

Check, recorded against the dry-run numbers ([#1579](https://github.com/openaustralia/morph/issues/1579), data-migration verification): MySQL row counts and checksums, SQLite file counts and sizes, Elasticsearch document counts. Record the elapsed time of this whole step.

Go/no-go checkpoint (inferred): if the elapsed time is on course to overrun the announced window, stop here and use R1.

Rollback point R1: wipe nothing on the old server. Abandon the new server's loaded data, because the rehearsal can be re-synced for another attempt.

### 4. Smoke test the new server

Action: point every name the smoke test uses at the new server from the tester's own machine only, with hosts-file entries or `curl --resolve`: `morph.io`, `www`, `api`, `faye` and `help` (and `discuss` if used). They are CNAMEs to `morph.io` in DNS, so a hosts entry for `morph.io` alone does not move them, and live log streaming (`faye`) and Discourse (`help`) would otherwise test the old server ([#1573](https://github.com/openaustralia/morph/issues/1573)). Work through the smoke-test checklist:

1. Pages load over TLS with the right certificate.
2. Sign in through the GitHub App using the test account.
3. Run a test scraper and watch live log streaming.
4. Fetch data through the API and compare the response shape with the old server's.
5. Search for a known scraper.
6. Open the admin area.
7. Send one real email through Postal to a maintainer.
8. Open Discourse and check topics and accounts, and that signing in through DiscourseConnect lands on `morph.io`.

Starting a run may be refused while read-only mode is on: the API run endpoint returns "You currently can't start a scraper run" in that mode (verified in [`app/controllers/api_controller.rb`](../../app/controllers/api_controller.rb), `can_run`). The restore carries the frozen production setting across, so the new server starts read-only. Only the tester's hosts override reaches the new server at this point, so read-only mode can be switched off on the new server for the test run and **must be switched back on before step 5** (inferred; whether a run can start under read-only on the new server is untested, so settle it in a dry run). Cron stays off on the new server throughout.

Check: every item above passes, and read-only mode is back on for the new server, confirmed by the banner on a signed-out request through the same hosts override. Any failure is a no-go.

Rollback point R1: this is the last cheap exit. Nothing public has changed. Delete the test scraper and its sign-in leftovers afterwards ([#1573](https://github.com/openaustralia/morph/issues/1573)).

### 5. Flip DNS with Terraform

Action: apply the reviewed `morph.io` A record merge request in `openaustralia/infrastructure`, with the site still read-only and cron still off ([#1573](https://github.com/openaustralia/morph/issues/1573)). Follow that repository's GitLab process for applying Terraform; the apply mechanism is not described in this repository.

Check:

- `dig` against a public resolver returns the new address for `morph.io`, and the names that are CNAMEs follow it. TTL is 300 seconds, so allow a few minutes (from #1573).
- Read-only mode is on at the new server before and after the flip (the banner shows to a signed-out visitor).
- Public checks: `https://morph.io` loads and serves the read-only banner, `https://api.morph.io` responds, `https://help.morph.io` loads, live log streaming through `faye.morph.io` connects.
- The old server stops receiving new page requests (check its nginx log).

Rollback point R2: apply the revert merge request. DNS flips back within the TTL, then turn read-only mode off and the old server's `cron_enabled` back on, restart workers there. Read-only mode blocks scraper and API-key changes but not sign-in: the GitHub callback creates or updates a user (verified in `User.find_for_github_oauth` in [`app/models/user.rb`](../../app/models/user.rb), and no controller other than the API run endpoint checks read-only mode), so an account created between the flip and step 6 is lost on R2. Forum writes are a separate gap. Both are open question 6 ([#1573](https://github.com/openaustralia/morph/issues/1573)). The old server's Redis still holds its schedule. Delete smoke-test leftovers on the new server afterwards. Post a "change of plan" note on the forum.

### 6. Open the site

Action, in this order:

1. Turn read-only mode off on the new server.
2. Turn `cron_enabled` on for the **new** server only. The check in `site.yml` refuses to run if more than one morph host has it on ([#1567](https://github.com/openaustralia/morph/issues/1567)), so the old server's flag must already be off.
3. Run `auto_run_scrapers` once on the new server as the application user, in the production Rails environment. The task is `app:auto_run_scrapers`, defined in [`lib/tasks/app.rake`](../../lib/tasks/app.rake) (verified). It queues every scraper with `auto_run` set, spread over the next 24 hours, and prints `Queued N scrapers to run over the next 24 hours`. Copy the exact invocation from the cron line the roles install, because that is not in this repository.
4. Post the "finished" follow-up on the forum ([#1576](https://github.com/openaustralia/morph/issues/1576)).

Check:

- The admin dashboard shows read-only mode off; a signed-in test person can create a scraper.
- `auto_run_scrapers` printed a count close to the number of scrapers with auto run on.
- The first scheduled runs start, finish, and their log lines stream live.
- Sentry receives events from the new server, and its uptime check on `morph.io` and `help.morph.io` is green ([#1574](https://github.com/openaustralia/morph/issues/1574)).
- The new server's Sidekiq shows no growing retry set.

**Rollback point R3 is the point of no return.** From here the site is roll-forward only. There is no reverse sync from the new server to the old one ([#1573](https://github.com/openaustralia/morph/issues/1573)). Do not run this step until every check in steps 4 and 5 passed.

What to expect after opening ([#1573](https://github.com/openaustralia/morph/issues/1573)):

- Most of the old server's day of scheduled runs is waiting in its Redis and never moves, so running the task once replaces that schedule straight away.
- The 10:00 cron the next morning queues another cycle, so for a few hours some scrapers get two runs close together. The concurrent-scraper cap absorbs it (unverified how mild this is).
- Jobs that came due during the window raised in `ScraperAutoRunWorker` and went to the old server's retry set, which is not carried across. The one `auto_run_scrapers` run covers them.

### 7. Undo the rehearsal safeguards

Action ([#1573](https://github.com/openaustralia/morph/issues/1573), [#1567](https://github.com/openaustralia/morph/issues/1567)):

1. Remove the `new.morph.io` and `new-help.morph.io` records and their basic auth.
2. Remove the extra GitHub App callback URL that was added for rehearsal.
3. Confirm no data scrub script is scheduled to run against production. The scrub was only for dry-run restores and is excluded from cutover (from #1567).
4. Set reverse DNS for the new address, if Linode needs the forward record to match first. #1573 did not verify that ordering, and it matters little because mail goes through Postal.

Check: `new.morph.io` and `new-help.morph.io` no longer resolve; signing in through GitHub still works; the callback URL list contains only production's.

No rollback point: these are clean-ups and each is reversible by redoing it, but they are not part of rollback.

## After the window

### 8. Backfill, watch and decommission

**Backfill the archived `log_lines`** ([#1601](https://github.com/openaustralia/morph/issues/1601))

Action:

1. Before loading, check that the new server's `log_lines` auto-increment value starts above production's highest id at dump time, so new rows cannot collide with archived rows ([map](https://github.com/openaustralia/morph/issues/1557), "Not yet specified"). If it does not, raise it first.
2. Run the archive load with `loadDdl: false` at a low thread count in nightly off-peak slots, stopped by morning (from #1601; the option names come from [MySQL Shell](https://dev.mysql.com/doc/mysql-shell/8.4/en/) docs, not a run).
3. Raise the throttle if it is not done within 3 weeks.

Check: the loaded row count equals the archive's recorded count with overlap counted once; a sample of old runs shows their log lines; a re-run changes nothing. Until then, old runs show no log lines, which the announcement says.

**First nightly jobs on the new server** ([#1574](https://github.com/openaustralia/morph/issues/1574))

Action: watch only, no change, on the morning after opening.

Check:

- The nightly dump (`mysqldump | zstd`) ran, and the restic job ran after it, so it uploaded that night's dump.
- Sentry cron monitors reported for `auto_run_scrapers`, `send_alerts`, `stop_long_running_scrapers`, the dump and the backup.
- `send_alerts` (11:30) sent through Postal and none failed.
- `searchkick:reindex:all` (06:00) ran and search still returns scrapers.
- The old `duply` chains under `oaf-backups/morph/` are left untouched until a person deletes them after the new restic repository has proven itself ([#1574](https://github.com/openaustralia/morph/issues/1574)).

**Decommission the old server** ([#1573](https://github.com/openaustralia/morph/issues/1573), [#1579](https://github.com/openaustralia/morph/issues/1579))

The clock starts at the DNS flip (step 5). Dates are counted from there, not fixed here.

| Stage | Length | State | Action | Check before moving on |
| --- | --- | --- | --- | --- |
| A | 14 days from the flip | Stopped (see [open questions](#open-questions) for what "stopped" means) | Confirm services, cron and mail are stopped on the old server and leave the instance as it is | No complaint or data gap needs the old server; the new server's backups have run and a restore has been proven |
| B | a further 14 days | Powered off | At day 14, power off the old instance in Linode | Nothing has needed it; the `log_lines` backfill is complete |
| C | at day 28 | Deleted | At day 28, open the deletion merge request (below) | The plan shows only the old resources |

Action for stage C, through a GitLab merge request in `openaustralia/infrastructure`:

1. Delete the old instance and its Linode Backups, and its Terraform resources `linode_instance.main` and `linode_rdns.main` (from #1573). Never rename `main`: a rename would replace the live server. Confirm which instance is which before applying.
2. Remove the S3 `log_lines` archive, which is kept until the old Linode is deleted ([#1601](https://github.com/openaustralia/morph/issues/1601)).
3. Delete `provisioning/`, the `Vagrantfile` and the Makefile Ansible targets from this repository ([#1566](https://github.com/openaustralia/morph/issues/1566), [ADR 0002](../adr/0002-provision-the-new-server-from-the-infrastructure-repository.md)). Decide at the same time whether the old `iptables-morph-*` files go or stay for #1506 ([#1600](https://github.com/openaustralia/morph/issues/1600)).
4. Close #1579 and the map.

Check: the Terraform plan shows only the old instance, its rDNS record and its backups being destroyed, and nothing for the new instance.

No rollback after stage C.

## Rollback

Rollback is a DNS flip back once DNS has moved (R2), and an undo of the freeze before that (R1), and it is possible **only until the site opens**. After that it is roll-forward only.

| Point | Reached at | How to roll back | What it costs |
| --- | --- | --- | --- |
| R0 | Before the window | Revert the merge to `main` | Nothing public changed |
| R1 | Steps 1 to 4 | Read-only mode off; old `cron_enabled` on; restart workers on the old server. No DNS change | Time lost; announce a change of plan |
| R2 | Step 5, before opening | Apply the reviewed revert merge request; then as R1 | DNS propagation within the TTL; delete smoke-test leftovers on the new server |
| R3 | Step 6 onward | None. Fix forward on the new server | Writes made on the new server since opening exist only there; no reverse sync |

Triggers (inferred, to confirm in a dry run): any failed smoke-test item, a data check that does not match, a missing certificate, or a projected overrun of the announced window before step 6. After step 6, a failure is a fix-forward incident, not a rollback.

## Status of claims in this runbook

Read on 2026-11-27 against `feature/1579-new-server` at the time of writing.

**Verified in this repository**

- `SiteSetting.read_only_mode` and `toggle_read_only_mode!` exist, the admin dashboard has the toggle button, and abilities and `ScraperAutoRunWorker` honour it.
- The read-only notice is only shown to signed-in people (layout change on `main` still outstanding).
- `app:auto_run_scrapers`, `app:send_alerts` and `app:stop_long_running_scrapers` are defined in `lib/tasks/app.rake`, and `auto_run_scrapers` queues over 24 hours.
- Sidekiq queues are `default` and `scraper`, and the Sidekiq dashboard is mounted at `/admin/jobs`.
- `honeybadger` is still in the `Gemfile` and `require "capistrano/honeybadger"` is still in the `Capfile`.
- `config/deploy/production.rb` exists and hard-codes an IP address; there is no `rehearsal` stage on the branch yet.

**Not checkable here (infrastructure repository, Terraform, accounts)**

- `cron_enabled`, `morph_stage`, certificate issuing, the Terraform records and merge requests, the cron lines, and the `site.yml` guard.
- The exact commands for the reindex, the dump and load, the rsync delta and the Terraform apply. Take them from the dry-run log.

**Inferred by this runbook**

- The placement of the cutover merge, the order of the stage rename before the final delta, the revert merge request, the go/no-go checkpoints, the timing of the restic credentials, the Discourse hostname at cutover, and the read-only toggle around the smoke test.

## Open questions

These need a decision before the runbook is final.

1. **What does "stopped" mean for the old server?** The spec and #1592 say the old Linode is stopped for 14 days, then off for 14 days. #1573 says services, cron and mail are stopped at the flip but the instance stays powered on and reachable for 14 days, then is powered off for 14. This runbook follows #1573. Confirm that is the intent.
2. **When does the cutover merge land, and what host does the in-window deploy target?** ADR 0005 says the merge lands after the rehearsal server validates it, shortly before cutover, and #1575 says the merge adds the production stage. Two problems follow. First, once `production.rb` points at `morph.io`, a stray `cap production deploy` before the flip would push Ruby 3.4 code onto the old server, which is the hazard #1575 removed the production stage to avoid. Second, the stage rename in step 2 probably leaves Capistrano's absolute symlinks stale, so a deploy to the new server is needed before the smoke test, and it cannot use `morph.io` before DNS flips. This runbook puts the merge before the window (P1) and assumes a hosts or ssh override for the in-window deploy. Options: merge before the window with a guard in `production.rb`; merge inside the window just before step 2; or keep deploying the `rehearsal` stage and rename it only at the flip. Which, for both the app and the forum?
3. **Keep the pre-reviewed revert merge request?** This runbook adds one so rollback at R2 is a single action. No ticket asks for it. Keep it, or revert by hand if needed?
4. **Smoke test while read-only is on.** This runbook turns read-only off on the new server only for the test run, then back on before the flip. Is that acceptable, or should the test run happen another way?
5. **Restic credentials timing.** Confirm they are installed in step 3 and not earlier or later.
6. **Are sign-ups and forum posts handled during the window?** Read-only mode does not stop GitHub sign-in, which creates or updates a user, so people can create accounts on the old server after the final dump (never copied across) and on the new server after the flip (lost on R2). No ticket decides whether to block sign-in during the window. Read-only mode covers the morph.io app, not Discourse. #1573 restores a fresh Discourse backup in step 3 and #1576 says the forum is unavailable for part of the window, but no ticket says the old forum is put in read-only or maintenance mode. Without that, posts and sign-ups on the old forum after the backup, or on the new one after the flip, are lost on rollback (R2) or never arrive. Options: freeze the old forum from the step 3 backup until the flip, or take the backup as late as possible and accept a small gap. Which?
