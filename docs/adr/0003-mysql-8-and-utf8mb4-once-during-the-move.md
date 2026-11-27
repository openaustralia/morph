# Convert to MySQL 8.4 and utf8mb4 once, during the server move

Status: accepted

Production MySQL 5.7 holds a mix of latin1 and utf8mb3 encodings: tables
differ between production and a freshly migrated development database
(#1494), and 4-byte UTF-8 such as emoji in scraper output causes production
errors (#1453). Rather than an in-place `ALTER` on the old server or
carrying the mess to the new one, the whole database is converted to
`utf8mb4`/`utf8mb4_unicode_ci` exactly once, as part of the 5.7 to 8.4
dump/restore during the server migration: a fresh database with correct
defaults, data migrated in, names swapped. The provisioned `database.yml`
sets explicit charset and collation so the schema never drifts again.

## Considered options

- In-place `ALTER TABLE` on the current server: risks index length limits
  and mojibake on latin1-stored-as-utf8 rows, on a box with no rehearsal
  environment.
- Migrate encodings later, after cutover: carries the known emoji failures
  onto the new server and means a second maintenance window.

Verification is per-table row counts and value hashes plus sampled values,
rehearsed against a production dump before cutover (see the update below for
why it is not `CHECKSUM TABLE`).

## Update, 2026-11-27: MySQL 8.4, and how the restore works

The decision above stands: convert to `utf8mb4`/`utf8mb4_unicode_ci` once, by
dump and restore. These facts moved since it was written (#1562, #1571, #1569,
#1601), and this record is amended in place rather than superseded.

- **The target is MySQL 8.4, not 8.0.** Ubuntu 26.04 ships 8.4 and packages no
  8.0, and Percona publishes no 26.04 build.
- **5.7 cannot load straight into 8.4.** MySQL does not skip the 8.0 series,
  so the route is MySQL Shell: run `checkForServerUpgrade` for 8.4 against the
  source, then `util.loadDump` with `ignoreVersion: true`.
- **The collation is `utf8mb4_unicode_ci`, as above.** It exists on 5.7 and
  8.4, so development, CI and production can match, and the four unique
  indexes on string columns (`domains.name`, `scrapers.full_name`, `scrapers`
  `owner_id` plus `name`, `webhooks` `scraper_id` plus `url`) held only ASCII
  and no trailing spaces when read on 2026-10-20, so loosening to
  `unicode_ci` creates no duplicates. `utf8mb4_0900_ai_ci`, the 8.4 default,
  and `utf8mb4_general_ci` were considered and not chosen.
- **Production does not match `schema.rb`.** 16 tables are `utf8_general_ci`
  and 4 (`ar_internal_metadata`, `collaborations`, `webhook_deliveries`,
  `webhooks`) are `latin1_swedish_ci`. The restore therefore loads production's
  own DDL into an empty database, converts every table with
  `ALTER TABLE ... CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci`
  while it is still empty (instant, nothing to truncate or garble), and only
  then loads the data. The dump files are utf8mb4, so each value is converted
  once, on the way in.
- **The dump is filtered.** `log_lines` is about 111 GB of the 117 GB, so the
  cutover dump carries only the retained rows (the rule of
  `Scraper#trim_log_lines`), and older rows are archived to S3 and backfilled
  after cutover. Production's `log_lines` is never modified.
- **Verification is row counts plus sampled values, not checksums.**
  `CHECKSUM TABLE` hashes stored bytes, so it differs on every converted
  table. Each side instead hashes the values it returns to a utf8mb4
  connection, whole for small tables and on a fixed sample of ids for large
  ones, and the target's `AUTO_INCREMENT` is checked to sit above the source's
  highest id. `CHECKSUM TABLE` is used only target against target, to show that
  re-running the backfill changes nothing.

The tooling is in `app/lib/morph/mysql_migration/` and `lib/tasks/mysql_migration.rake`,
and the runbook is `docs/mysql_migration.md`.
