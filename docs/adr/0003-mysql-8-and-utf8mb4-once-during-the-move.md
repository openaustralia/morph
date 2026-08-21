# Convert to MySQL 8.0 and utf8mb4 once, during the server move

Status: accepted

Production MySQL 5.7 holds a mix of latin1 and utf8mb3 encodings: tables
differ between production and a freshly migrated development database
(#1494), and 4-byte UTF-8 such as emoji in scraper output causes production
errors (#1453). Rather than an in-place `ALTER` on the old server or
carrying the mess to the new one, the whole database is converted to
`utf8mb4`/`utf8mb4_unicode_ci` exactly once, as part of the 5.7 to 8.0
dump/restore during the server migration: a fresh database with correct
defaults, data migrated in, names swapped. The provisioned `database.yml`
sets explicit charset and collation so the schema never drifts again.

## Considered options

- In-place `ALTER TABLE` on the current server: risks index length limits
  and mojibake on latin1-stored-as-utf8 rows, on a box with no rehearsal
  environment.
- Migrate encodings later, after cutover: carries the known emoji failures
  onto the new server and means a second maintenance window.

Verification is per-table row counts and checksums plus spot-checks of
known-emoji rows, rehearsed against a production dump before cutover.
