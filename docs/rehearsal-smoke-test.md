# Rehearsal smoke test

The end-to-end checklist for the rehearsal server at `https://new.morph.io`. Run it:

- after each deploy to the rehearsal stage (`cap rehearsal deploy`)
- after each dry-run restore, once the data scrub has run
- once more on the new server in the cutover window, before the DNS flip

The cutover runbook and the two dry runs point here, so this file is the single copy. A step passes only if the result described under it is what you see. Record any failure on [#1587](https://github.com/openaustralia/morph/issues/1587) with the step number.

The rehearsal stage and this server's rehearsal names are retired at cutover ([#1579](https://github.com/openaustralia/morph/issues/1579)). The first production deploy goes straight to `/srv/www/production` in the window, with no rename of `/srv/www/rehearsal`. In the cutover window the same checklist runs against `morph.io` through a hosts-file or `curl --resolve` override, with `/srv/www/production` in place of `/srv/www/rehearsal` in the paths below.

## Read-only mode

The smoke test runs with site-wide read-only mode on, as it will be at cutover, with **one documented exception**: read-only mode blocks starting a scraper run, creating or updating scrapers and resetting an API key, so running the throwaway test scraper needs read-only off for a short time. That exception is part B below. Read-only mode is then switched back on and checked in part C, before anything else happens. In the cutover window that must be done before the DNS flip.

The toggle is the "Switch off site-wide read-only mode" or "Go into site-wide read-only mode" button on the admin dashboard (`/admin`). Per the spec, read-only mode also refuses new sign-ups (not checked in this repository), so use a test account that already exists.

Decisions behind this: [#1567](https://github.com/openaustralia/morph/issues/1567) (rehearsal safeguards), [#1595](https://github.com/openaustralia/morph/issues/1595) (deploy path) and the spec [#1579](https://github.com/openaustralia/morph/issues/1579).

## Before you start

[#1557](https://github.com/openaustralia/morph/issues/1557) still lists the test GitHub account and test scrapers as not yet specified, so treat them as open items, not things that exist.

- The basic auth user and password for new.morph.io, from the vault. Every request below needs them, including `curl` (`-u`) and the browser's websocket.
- The rehearsal callback URL added to production's GitHub App (removed again at cutover).
- A test GitHub account that has already signed in once, and a small test scraper repository in it. Never run a real production scraper here, because it would hit its target site a second time.
- A browser window that is not signed in to morph.io.
- Use placeholders below: `<basic-auth-user>`, `<password>`, `<test-user>`, `<test-scraper>`, `<api-key>`. Never paste real values into an issue or pull request.

Commands run on the server need the `deploy` user's rbenv shims on the `PATH`. Use a login shell (`ssh -t deploy@new.morph.io bash -l`). If `bundle` is not found or the Ruby version is wrong, that is a setup problem to record, not a failure of the step.

## Part A: read-only mode on

### A1. Read-only mode is on

Sign in as an admin (step A3 explains how) and open `/admin`.

Expected: the dashboard offers "Switch off site-wide read-only mode", which means read-only mode is on. If it offers "Go into site-wide read-only mode", press it. A restored database carries production's setting, so do not assume.

### A2. Sign in through the GitHub App

Open https://new.morph.io, pass basic auth, then choose "Sign in with GitHub" as the existing test account.

Expected: GitHub asks you to authorise, you return to new.morph.io (not morph.io) signed in as the test account, and a second sign-in works without an error page.

Fails if: you land on morph.io, or GitHub shows an error about the callback URL.

### A3. Admin area

On the server, as the `deploy` user in the `current` directory, run `RAILS_ENV=production bundle exec rake app:promote_to_admin` to promote the test account's nickname (the task prompts for the nickname on stdin, so type it when asked). Then open `/admin` and `/admin/jobs`.

Expected: the dashboard lists accounts and scrapers, and the Sidekiq page loads and shows the `default` and `scraper` queues.

### A4. Search

Search for the name of a scraper that is already in the restored data (or the throwaway scraper if part B has run) at https://new.morph.io/search.

Expected: the scraper is in the results.

If it is not, check that Elasticsearch is up and run `searchkick:reindex:all` once, because deploys do not reindex.

### A5. Mail goes to the sink

Only the alert email sends mail, and A6 means no alerts run, so send a test message instead. On the server, as the `deploy` user in the `current` directory:

```sh
RAILS_ENV=production bundle exec rails runner 'ActionMailer::Base.mail(from: "test@example.invalid", to: "sink@example.invalid", subject: "Rehearsal sink check", body: "ok").deliver_now'
```

Then open Mailpit (behind the same basic auth).

Expected: the message is in Mailpit, and no Postal credentials (`SMTP_USERNAME`, `SMTP_PASSWORD`) are in the server's `.env`. In the cutover window the Postal credentials are installed and this step instead sends one real email to a maintainer.

### A6. Scheduled jobs are off

The app has no switch of its own for this. Cron entries exist only when the host variable `cron_enabled` is on, and it is off for the rehearsal host ([#1567](https://github.com/openaustralia/morph/issues/1567)).

On the server, check `crontab -l` as `deploy` and as `root`.

Expected: no morph entries in either (no `auto_run_scrapers`, `send_alerts`, `stop_long_running_scrapers`, `docker_tidy_up`, `searchkick:reindex:all`, `sitemap:refresh`, dump or backup), and the server has no backup S3 credentials.

Also check that a deploy did not start real scrapers. The rehearsal stage skips `deploy:fix_queue_run_inconsistencies`, which would otherwise re-enqueue the restored production database's unfinished runs. Expected: `/admin/jobs` shows nothing queued or running on the `scraper` queue, and `docker ps` shows no scraper containers, until you start the test scraper yourself.

### A7. Writes are refused

As the test account, open the throwaway scraper's page (or any scraper's page) and look for "Run scraper" and the Settings page's "Reset key".

Expected: neither is offered, because read-only mode blocks them. This is the baseline that part C checks again.

## Part B: the exception, read-only off

Only this part runs with read-only off. Keep it short, and do the steps in order. On the real cutover window only the throwaway scraper is touched, and its leftovers are deleted afterwards ([#1573](https://github.com/openaustralia/morph/issues/1573)).

### B1. Switch read-only mode off

On the admin dashboard press "Switch off site-wide read-only mode".

Expected: the flash message says "Read-only mode is now off".

### B2. Run the throwaway test scraper

As the test account, add the test scraper from your list of repositories (skip if it already exists), then press "Run scraper".

Expected: the run goes from queued to running to finished, the scraper's page shows its records, and the SQLite file appears under `/srv/www/rehearsal/shared/db/scrapers` on the server.

### B3. Live log streaming

Watch the scraper page while B2 runs.

Expected: log lines appear as they are written, without reloading the page.

Streaming goes through faye and render_sync over a websocket. Open the browser's network tab and check the faye connection is not refused by basic auth. The infrastructure repository serves faye under `/faye` on new.morph.io with basic auth off for that path, because there is no `faye.new.morph.io` name.

### B4. API

A restored database has its `api_key` values cleared by the scrub, and signing in does not set a new one. Open the account's Settings page, press "Reset key", and copy the new key. Then run:

```sh
curl -u '<basic-auth-user>:<password>' \
  'https://new.morph.io/<test-user>/<test-scraper>/data.json?key=<api-key>&query=select%20*%20from%20data%20limit%201'
```

Expected: HTTP 200 and a JSON array containing a row from B2. The same call with a wrong key returns 401 "API key is not valid".

## Part C: read-only back on, verified

Do this straight after part B, before anything else.

### C1. Switch read-only mode back on

On the admin dashboard press "Go into site-wide read-only mode".

Expected: the flash message says "Read-only mode is now on".

### C2. Verify it

Repeat A7 and check the banner.

Expected: "Run scraper" and "Reset key" are no longer offered, a signed-out visitor sees the read-only notice (once the layout change on `main` for that notice has landed, [#1557](https://github.com/openaustralia/morph/issues/1557)), and the dashboard offers "Switch off site-wide read-only mode". Record the time on #1587. In the cutover window the DNS flip does not start until this check has passed.

## Not covered here

- Discourse on `new-help.morph.io`, which is checked separately ([#1586](https://github.com/openaustralia/morph/issues/1586)).
- Sending one real email through Postal, which happens only in the cutover smoke test, when the Postal credentials are installed.
