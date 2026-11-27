# Rehearsal smoke test

The end-to-end checklist for the rehearsal server at `https://new.morph.io`. Run it:

- after each deploy to the rehearsal stage (`cap rehearsal deploy`)
- after each dry-run restore, once the data scrub has run
- once more on the new server just before the DNS flip at cutover

The cutover runbook and the two dry runs point here, so this file is the single copy. A step passes only if the result described under it is what you see. Record any failure on [#1587](https://github.com/openaustralia/morph/issues/1587) with the step number.

Decisions behind this: [#1567](https://github.com/openaustralia/morph/issues/1567) (rehearsal safeguards), [#1595](https://github.com/openaustralia/morph/issues/1595) (deploy path) and the spec [#1579](https://github.com/openaustralia/morph/issues/1579).

## Before you start

[#1557](https://github.com/openaustralia/morph/issues/1557) still lists the test GitHub account and test scrapers as not yet specified, so treat them as open items, not things that exist.

- The basic auth user and password for new.morph.io, from the vault. Every request below needs them, including `curl` (`-u`) and the browser's websocket.
- The rehearsal callback URL added to production's GitHub App (removed again at cutover).
- A test GitHub account and a small test scraper repository in it. Never run a real production scraper here, because it would hit its target site a second time.
- A browser window that is not signed in to morph.io.
- Use placeholders below: `<basic-auth-user>`, `<password>`, `<test-user>`, `<test-scraper>`, `<api-key>`. Never paste real values into an issue or pull request.

## The checklist

Commands run on the server need the `deploy` user's rbenv shims on the `PATH`. Use a login shell (`ssh -t deploy@new.morph.io bash -l`). If `bundle` is not found or the Ruby version is wrong, that is a setup problem to record, not a failure of the step.

### 1. Sign in through the GitHub App

Open https://new.morph.io, pass basic auth, then choose "Sign in with GitHub" as the test account.

Expected: GitHub asks you to authorise, you return to new.morph.io (not morph.io) signed in as the test account, and a second sign-in works without an error page.

Fails if: you land on morph.io, or GitHub shows an error about the callback URL.

### 2. Run a test scraper

Add the test scraper from your list of repositories, then press "Run scraper".

Expected: the run goes from queued to running to finished, the scraper's page shows its records, and the SQLite file appears under `/srv/www/rehearsal/shared/db/scrapers` on the server.

### 3. Live log streaming

Watch the scraper page while step 2 runs.

Expected: log lines appear as they are written, without reloading the page.

Streaming goes through faye and render_sync over a websocket. Open the browser's network tab and check the faye connection is not refused by basic auth. The infrastructure repository serves faye under `/faye` on new.morph.io with basic auth off for that path, because there is no `faye.new.morph.io` name.

### 4. API

A restored database has its `api_key` values cleared by the scrub, and signing in does not set a new one. Open the account's Settings page, press "Reset key", and copy the new key. Then run:

```sh
curl -u '<basic-auth-user>:<password>' \
  'https://new.morph.io/<test-user>/<test-scraper>/data.json?key=<api-key>&query=select%20*%20from%20data%20limit%201'
```

Expected: HTTP 200 and a JSON array containing a row from step 2. The same call with a wrong key returns 401 "API key is not valid".

### 5. Search

Search for the test scraper's name at https://new.morph.io/search.

Expected: the scraper is in the results.

If it is not, check that Elasticsearch is up and run `searchkick:reindex:all` once, because deploys do not reindex.

### 6. Admin area

On the server, as the `deploy` user in the `current` directory, run `RAILS_ENV=production bundle exec rake app:promote_to_admin` to promote the test account's nickname (the task prompts for the nickname on stdin, so type it when asked). Then open `/admin` and `/admin/jobs`.

Expected: the dashboard lists accounts and scrapers, and the Sidekiq page loads and shows the `default` and `scraper` queues.

### 7. Mail goes to the sink

Only the alert email sends mail, and step 8 means no alerts run, so send a test message instead. On the server, as the `deploy` user in the `current` directory:

```sh
RAILS_ENV=production bundle exec rails runner 'ActionMailer::Base.mail(from: "test@example.invalid", to: "sink@example.invalid", subject: "Rehearsal sink check", body: "ok").deliver_now'
```

Then open Mailpit (behind the same basic auth).

Expected: the message is in Mailpit, and no Postal credentials (`SMTP_USERNAME`, `SMTP_PASSWORD`) are in the server's `.env`.

### 8. Scheduled jobs are off

The app has no switch of its own for this. Cron entries exist only when the host variable `cron_enabled` is on, and it is off for the rehearsal host ([#1567](https://github.com/openaustralia/morph/issues/1567)).

On the server, check `crontab -l` as `deploy` and as `root`.

Expected: no morph entries in either (no `auto_run_scrapers`, `send_alerts`, `stop_long_running_scrapers`, `docker_tidy_up`, `searchkick:reindex:all`, `sitemap:refresh`, dump or backup), and the server has no backup S3 credentials.

Also check that a deploy did not start real scrapers. The rehearsal stage skips `deploy:fix_queue_run_inconsistencies`, which would otherwise re-enqueue the restored production database's unfinished runs. Expected: `/admin/jobs` shows nothing queued or running on the `scraper` queue, and `docker ps` shows no scraper containers, until you start the test scraper yourself.

### 9. Links survive the stage rename (dry runs, and after the rename at cutover)

Cutover renames `/srv/www/rehearsal` to `/srv/www/production` on the same disk ([#1595](https://github.com/openaustralia/morph/issues/1595)). This branch rewrites Capistrano's `current` and shared links as relative links after each deploy (`lib/capistrano/tasks/relative_symlinks.cap`), so the rename does not leave those links stale. It does not cover files that hold an absolute path, such as `.bundle/config`, so check both.

On a dry run, with services stopped, do the rename yourself:

```sh
find /srv/www/rehearsal/releases/ -maxdepth 4 -type l -printf '%p -> %l\n'
sudo mv /srv/www/rehearsal /srv/www/production
```

At cutover the runbook has already done the rename (and the smoke test runs against `/srv/www/production`), so run only the checks below.

```sh
find /srv/www/production -xtype l
readlink /srv/www/production/current
grep -r '/srv/www/rehearsal' /srv/www/production/current/.bundle /srv/www/production/current/config
cd /srv/www/production/current && bundle check
```

Expected: every link printed by the first command is relative (no `/srv/www/rehearsal` in any target); `find -xtype l` prints nothing (no broken links); `readlink` prints `releases/<timestamp>`; `db/scrapers` still holds the scraper data; the `grep` prints nothing; `bundle check` says the dependencies are satisfied.

Known gap: capistrano-bundler writes `BUNDLE_PATH` as the absolute `/srv/www/rehearsal/shared/bundle` into `.bundle/config`. If the `grep` finds it, Bundler will not find its gems after the rename until the release is redeployed, so the cutover runbook's in-window deploy question ([#1614](https://github.com/openaustralia/morph/pull/1614)) is not closed by this change. That needs a human decision, for example redeploying after the rename or changing `bundle_path`.

Also check whether any process stores an absolute path under `shared` (for example a scraper container mount) that the rename would leave stale. [#1595](https://github.com/openaustralia/morph/issues/1595) lists this as unverified.

## Not covered here

- Discourse on `new-help.morph.io`, which is checked separately ([#1586](https://github.com/openaustralia/morph/issues/1586)).
- Sending one real email through Postal, which happens only in the cutover smoke test, when the Postal credentials are installed.
