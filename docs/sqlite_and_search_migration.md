# Moving the SQLite databases and Elasticsearch for the new server

Tooling for #1589, part of #1579. It copies the scraper SQLite databases and
repos (`db/scrapers`, about 123 GB) from the old server by bulk copy plus a
final delta, rebuilds Elasticsearch from the database rather than migrating the
old index, and checks both. The decisions are in #1569 (how each data store
moves), #1572 (Elasticsearch 8.19) and #1595 (deploy path).

Redis is not carried over. The new server starts with an empty Redis, so there
is no Redis copy code and nothing to verify. Sidekiq's retry and dead sets on
the old server are discarded.

Nothing here touches `db/scrapers` on the machine you run it on, except that
the copy writes to whatever destination you name. Never point the destination at
a server that is serving production traffic.

## What is where

- `app/lib/morph/sqlite_migration/` has the copy (`sync.rb`) and the file
  listing and comparison (`manifest.rb`, `comparison_report.rb`).
- `app/lib/morph/search_migration/reindexer.rb` has the reindex and the counts.
- `lib/tasks/sqlite_migration.rake` and `lib/tasks/search_migration.rake` have
  the tasks.
- `spec/` has the specs. The copy and reindex are driven through an injected
  runner and doubles, plus one real rsync copy between temporary directories
  (skipped if rsync is not installed). The checks that need real servers are
  manual and listed in `TESTING.md`.

## SQLite databases and repos

Run these on the **new** server, pulling from the old one over ssh. Authentication
is whatever ssh already has (an agent, or a key named in `SSH_COMMAND`). No task
takes a password, and a location with one in it is refused.

| Variable | Meaning |
| --- | --- |
| `SQLITE_SOURCE` | Required. `user@old-host:/path/to/db/scrapers` or a local path |
| `SQLITE_DESTINATION` | Required. For rehearsal, `/srv/www/rehearsal/shared/db/scrapers` (#1595) |
| `SSH_COMMAND` | Optional. For example `ssh -i ~/.ssh/<key> -o BatchMode=yes` |
| `BWLIMIT_KBPS` | Optional. Caps the speed so the bulk copy does not starve the live server |
| `DRY_RUN` | `1` lists what would be copied and changes nothing |
| `LOG_FILE` | Optional. Appends one JSON line per run, for the dry run record |
| `DELETE`, `MAX_DELETE` | Delta only. `DELETE=1` also needs `MAX_DELETE=N` |

1. **Bulk copy, days ahead and repeated.**
   `bundle exec rake app:sqlite_migration:bulk`. It resumes after an
   interruption, because rsync skips files that already match and `--inplace`
   continues a half-copied file. Files that vanish while scrapers run are a
   warning, not a failure. The task prints elapsed time and transfer speed, and
   `LOG_FILE` keeps them. The first run is where #1558's unmeasured transfer
   speed gets measured.
2. **Final delta, inside the window, after the freeze.**
   The freeze stops the cron jobs and drains the `scraper` queue (#1569), so
   nothing should change underneath it. Run
   `DELETE=1 MAX_DELETE=200 bundle exec rake app:sqlite_migration:delta` so
   scrapers deleted since the bulk copy disappear from the destination too.
   `--max-delete` stops a wrong source from emptying the destination. Unlike the
   bulk copy, vanished files fail the delta.
3. **Verify.** Make a listing on each side and compare them (below).

The destination path is renamed from `rehearsal` to `production` on the same disk
at cutover (#1595), so the bulk copy never moves again.

### Verifying file counts and sizes

A manifest is one `relative/path<TAB>size` line per file, sorted. The old server
runs main on Ruby 3.0.7 and cannot run this branch, but it can make the same
listing with the shell:

```sh
find db/scrapers/ -type f -printf '%P\t%s\n' | sort > source.tsv
```

Keep the trailing slash: `db/scrapers` is a symlink into `shared/` on a deployed server, and `find` only follows it with the slash. File names containing tabs are handled; file names containing newlines are not, and would need a `-print0` format.

On the new server, either use the same `find` or
`DIR=/srv/www/rehearsal/shared/db/scrapers OUTPUT=destination.tsv bundle exec rake app:sqlite_migration:manifest`.
Then, with both files in one place:

```sh
SOURCE_MANIFEST=source.tsv DESTINATION_MANIFEST=destination.tsv \
  bundle exec rake app:sqlite_migration:verify
```

It prints file and byte totals overall, for `*.sqlite` files, and for `data/` and
`repos/` separately, then lists files that are missing, extra or a different
size, and ends with `RESULT: match` or `RESULT: MISMATCH` (exit status 1). Paste
the output into the dry run record. Compare after the delta pass, not before,
because the source changes while scrapers run. Sizes are compared, not
checksums. A checksum pass over 123 GB is a decision for the dry run if the
sizes are not enough.

## Elasticsearch

Run after the database has loaded, with the cron jobs and workers stopped.

```sh
bundle exec rake app:search_migration:reindex
```

It rebuilds the `Scraper` and `Owner` indexes with Searchkick's `reindex`, which
builds a fresh index, fills it and then swaps the alias, so nothing from the old
index carries over. It prints the Elasticsearch version, a progress line every
15 seconds, the time taken and the document counts against the database, and
exits 1 if they differ. The `Owner` index covers people and organisations, which
share one table.

```sh
bundle exec rake app:search_migration:verify
```

Counts only, safe at any time. To put the old server's counts in the record, take
them there (for example `curl -s localhost:9200/_cat/count/scrapers_production`)
and pass `SOURCE_COUNTS=Scraper=N,Owner=N`. The old index names depend on the
environment, so check `_cat/indices` first.

Elasticsearch 8.19 with the 7.17 client gem needs `ELASTIC_CLIENT_APIVERSIONING=true`
in the server's environment and the `Content-Type` override from PR #1613. Without
both, indexing and search fail with a 400. This tooling uses only Searchkick's
public API and works on either version.
