# Moving MySQL to 8.4 for the new server

Tooling for #1588, part of #1579. It moves the MySQL 5.7 data to MySQL 8.4 with
`utf8mb4_unicode_ci` by a filtered dump of the retained `log_lines`, archives the
older `log_lines` to S3 for backfill after cutover, scrubs the restored copy on
the rehearsal server, and verifies the result. ADR 0003 records the decisions.

All of it lives on the `feature/1579-new-server` branch and runs on the new
(rehearsal) server, because it needs MySQL Shell 8.4 and Ruby 3.4. It reads the
old server's MySQL through a URL you supply, usually an SSH tunnel. Nothing in it
writes to the source.

## What is where

- `app/lib/morph/mysql_migration/` has the logic. `steps.rb` is what each rake
  task calls, and every step writes a JSON report with its elapsed time to
  `tmp/mysql_migration/` (or `MYSQL_MIGRATION_REPORT_DIR`).
- `lib/tasks/mysql_migration.rake` has the tasks.
- `spec/lib/morph/mysql_migration/` has the specs. MySQL Shell itself is not run
  by them, so the parts that run it are `# :nocov:` and listed in `TESTING.md`.

## Settings

Everything comes from environment variables. None has a default for the two
servers, and the tasks refuse to run if the target is the source.

| Variable | Meaning |
| --- | --- |
| `MYSQL_MIGRATION_SOURCE_URL` | Old server, such as `mysql2://user:password@127.0.0.1:3307/scraping_production` (through a tunnel) |
| `MYSQL_MIGRATION_TARGET_URL` | New MySQL 8.4 server and the database name to create |
| `MYSQL_MIGRATION_DUMP_DIR` | Local directory for the cutover dump. It must not exist yet |
| `MYSQL_MIGRATION_THREADS` | Dump and load threads (default 4) |
| `MYSQL_MIGRATION_BACKFILL_THREADS` | Threads for the backfill, the only throttle it has (default 1) |
| `MYSQL_MIGRATION_S3_BUCKET` | The archive bucket, such as `example-morph-migration-archive`. Required, no default. See "The archive bucket" below |
| `MYSQL_MIGRATION_S3_PREFIX` | Key prefix for the archive, such as `log_lines`. Required, no default |
| `MYSQL_MIGRATION_ARCHIVE_DIR` | Practice only: a local directory used instead of S3 |
| `MYSQL_MIGRATION_S3_REGION`, `_S3_PROFILE`, `_S3_ENDPOINT` | Optional: region such as `ap-southeast-2`, a named AWS profile that holds the archive's own credentials, and an endpoint override |
| `MYSQL_MIGRATION_ARCHIVE_SLICE_ROWS` | Log line ids per archive slice (default 5,000,000) |
| `MYSQL_MIGRATION_ARCHIVE_MANIFEST` | Where the archive manifest is kept (default in the report directory) |
| `MORPH_REHEARSAL` | Must be exactly `true` for the scrub to run. See "What the infrastructure repository must provide" below |

The tasks load the Rails app, so the app must boot with its own database
settings. This was checked with the database missing in the test environment
only. If production mode objects to a database that does not exist yet, run
`rails db:create` first: `restore` then fixes its charset and collation.

Passwords reach MySQL Shell on stdin and the options go in a generated script
file, so no credential or long filter appears in a process list.

## The archive bucket

The archive goes to a separate bucket made for it, with its own credentials. It is
never the backup bucket, and the rehearsal server must not hold backup
credentials (#1567), because a rehearsal that wrote into the backup chains would
corrupt them.

- The bucket and prefix come from `MYSQL_MIGRATION_S3_BUCKET` and
  `MYSQL_MIGRATION_S3_PREFIX`. Neither has a default, and a task that needs them
  refuses to start without them.
- The credentials are the archive bucket's own. MySQL Shell reads them from the
  standard AWS environment variables (`AWS_ACCESS_KEY_ID` and
  `AWS_SECRET_ACCESS_KEY`, shown here as placeholders only) or from the profile
  named in `MYSQL_MIGRATION_S3_PROFILE`. This code never reads or stores them.
  Do not put them in the repository, in a report or in a command line.
- The rehearsal server's role may write and read only that bucket. In IAM terms
  that is `s3:ListBucket` on the bucket and `s3:GetObject`, `s3:PutObject` and
  `s3:AbortMultipartUpload` on its objects, and nothing else. This list has not
  been checked against MySQL Shell: confirm it on the first rehearsal dump.
- Delete the archive after the old Linode is deleted (#1601).

## What the infrastructure repository must provide

The roles and Terraform in the infrastructure repository (GitLab) need to match
these. The tasks expect exactly this:

- `MORPH_REHEARSAL=true` in the rehearsal host's `.env`. The name is exactly
  `MORPH_REHEARSAL` and the value exactly `true`: anything else, or the variable
  being absent, makes the scrub refuse. It must be removed at cutover together
  with `cron_enabled`, because the rehearsal server becomes production on the
  same disk (#1595). `SERVER_NAME` must be the rehearsal host name, such as
  `new.morph.io`: the scrub also refuses when it is `morph.io` or `www.morph.io`.
- The `mysql-shell` package, giving the `mysqlsh` command on the `PATH`. Ubuntu
  26.04 packages MySQL Shell 8.4.8 in universe (#1562), and the tasks were tried
  with 8.4.8, so install 8.4.x from that package and check the version with
  `mysqlsh --version`. The package name and version on 26.04 come from #1562 and
  have not been checked on a 26.04 host.
- `local_infile` switched on in MySQL 8.4, which `loadDump` needs on the target.
- The archive bucket and its credentials, as above, and nothing for the backup bucket.

## Order of work

1. `rake mysql_migration:check_source` runs MySQL Shell's upgrade checker for
   8.4 against the source and fails on errors in the data. Errors about the
   source server's own variables are recorded, not blocking: `default_authentication_plugin`
   is always an error on 5.7, and this is a dump and restore into a fresh server.
   Some checks need the server's configuration file and are listed as not run.
2. `rake mysql_migration:archive_log_lines` archives `log_lines` to S3 in slices
   of ids, days ahead. Each slice is its own MySQL Shell dump, taken without the
   global read lock because the rows are immutable. It can be stopped and started
   again: finished slices are in the manifest and are skipped. If a slice fails
   part way, delete its S3 prefix (named in the error) before running again,
   because MySQL Shell cannot resume a dump. The archive covers every id up to
   the highest at the time, retained rows included. That overlaps the cutover
   dump on purpose, so there is no gap, and the load replaces rows by id.
   Run it again close to cutover to top up if cutover is more than 30 days
   after the first run, since the cutover dump keeps a run only for 30 days.
3. In the window: `rake mysql_migration:dump` writes every table, with
   `log_lines` filtered to runs created in the last 30 days plus each scraper's
   last 3 successful and last 3 unsuccessful runs (the rule of
   `Scraper#trim_log_lines`). The ids are written into the filter as literals, to
   a file in the report directory as well. The dump is consistent.
4. `rake mysql_migration:restore` creates the database as `utf8mb4_unicode_ci`,
   loads production's own DDL, converts the still-empty tables, then loads the
   data. It refuses a database that already has tables, and `local_infile` must
   be on for the target.
5. `rake mysql_migration:verify` compares source and target and records the
   time. Run it before the scrub. It reads the `log_lines` filter the dump
   recorded (`log_lines_where.sql` in the report directory) rather than working
   it out again, because the 30-day cutoff moves on while the restore runs. It reports row counts, a value hash per table
   (whole for tables up to 500,000 rows, a fixed sample of ids above that),
   whether every collation is `utf8mb4_unicode_ci`, and whether the target's
   `AUTO_INCREMENT` is above the source's highest id. It exits non-zero on any
   difference. A live source keeps changing, so only a source that is frozen
   (the cutover window) can match exactly.
6. Rehearsal only: `rake mysql_migration:scrub` makes the restored copy unable
   to contact real people or services:
   - `owners.email` becomes `owner-<id>@example.invalid`
   - `owners.access_token` and `owners.remember_token` are cleared, and each
     `owners.api_key` becomes a distinct random key (a NULL key would match an API
     request that sends no key)
   - each `webhooks.url` becomes a distinct placeholder URL
   - every `variables.value`, which may hold a scraper's secret, becomes the one
     placeholder `scrubbed-for-rehearsal`, so a rehearsal scraper can never present a
     real secret to a third-party service
   - each `email_suppressions.address` becomes `suppressed-<id>@example.invalid`, and each
     `email_suppressions.reply_excerpt` becomes the fixed text `Reply text removed for rehearsal`
   - every IP address column becomes `192.0.2.1`, from the documentation range
     (RFC 5737). Empty values stay empty. From `db/schema.rb`, the columns are
     `owners.current_sign_in_ip`, `owners.last_sign_in_ip` and `runs.ip_address`.
     A spec fails if a migration adds a column with `ip` in its name that the
     scrub does not cover

   It refuses unless `MORPH_REHEARSAL` is `true`, and refuses when `SERVER_NAME` is
   `morph.io`. It then checks that no real value remains and fails if one does.
   `rake mysql_migration:verify_scrub` runs the same check on its own and changes
   nothing. API keys are random after the scrub, so that check can only report a
   missing key. The scrub is not part of the cutover and is outside the 4-hour timing.
   Free-text columns can still hold addresses or secrets, and are not scrubbed:
   `log_lines.text`, `api_queries.query`, `domains.meta` and `domains.title`,
   `active_admin_comments.body` and the `owners` profile fields (`name`, `nickname`,
   `blog`, `company`, `gravatar_url`). Decide on those before the first dry run.
7. After cutover: `rake mysql_migration:backfill_log_lines` loads the archive
   into the existing table, one slice at a time. Run it in off-peak slots and stop
   it in the morning: progress files let it resume, and re-loading a slice is
   harmless. Copy the manifest from the machine that made the archive first. When
   it is done, `VERIFY_SCOPE=backfill rake mysql_migration:verify` checks each archived
   id range holds the row count recorded when it was archived (the old server is
   stopped by then, so it needs only the target), and `rake mysql_migration:checksums` before and after a re-run
   (`BASELINE=` the earlier report) shows that a re-run changes nothing.

`DRY_RUN=1` on the dump, archive, restore and backfill tasks passes MySQL Shell's
`dryRun`, which checks the options without writing. Run each with it first.

## What has been tried

On a laptop, with a few dozen rows of fictional data, MySQL 5.7.33 and 8.4.13 in
Docker and MySQL Shell 8.4.8, every task ran end to end except the S3 part (a
local directory stood in through `MYSQL_MIGRATION_ARCHIVE_DIR`). That showed:

- MySQL Shell accepts the `where` filter on a 5.7 source, and the password on stdin works
- the restore ends with every table and column `utf8mb4_unicode_ci`, and `verify` passes
- `loadDump` with `loadDdl: false` into a populated 8.4 table, over rows that
  overlap the cutover dump, ends with the right count, and loading again with
  the progress files cleared changes nothing
- the scrub refuses without `MORPH_REHEARSAL=true` and works with it

## Not yet proved

Everything below needs the rehearsal server and real data, and is listed as
unchecked on the pull request:

- The archive and backfill against S3 itself
- The size of the filter with real data (at most about 67,000 literal ids, from 11,127 scrapers with 6 kept runs each), and the
  time for the dump, the load and `verify` on 117 GB, set against the 4-hour bar
- That `local_infile` and the privileges `loadDump` needs are available on the target
- The backfill's effect on web and scraper latency, and the thread count to use
