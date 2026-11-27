TESTING
=======

If you're running guard (see the "Guard Livereload" section in `README.md`) the tests will also automatically run when you change a file.

By default, RSpec will skip tests that have been tagged as being slow.
To change this behaviour, add the following to your `.env`:

    RUN_SLOW_TESTS=1

By default, RSpec will run certain tests against a running Docker server.
The GitHub actions exclude these tests.
These tests are quite slow, but not have been tagged as slow.
To stop Rspec from running these tests, add the following to your `.env`:

    DONT_RUN_DOCKER_TESTS=1

Github integration requires "config/morph-github-app.private-key.pem" to be present (see `README.md`)
You can force the test to be excluded by setting

    DONT_RUN_GITHUB_TESTS=1

For convenience, use the following command to run the quick tests first to see if something obviously broke, then run
the full suite:

    make test

Manual Tests
------------    

Tests that require a lot of setup have been left for manual testing.
Search for `# :nocov:` in the code to find code that needs manual testing.
This includes:

### Create a new repository

### Run the new repository through the pipeline

- Run the scraper
- Check that it creates records
- Check you can see the log output

### Delete the scraper

### Check you can readd the scraper from the list of repos on your account

### app:backup and app:restore rake tasks

Testing restore is too hard to automate. 

### Error reporting to Sentry

Automated tests only cover the SDK staying quiet when `SENTRY_DSN` is unset.
That an event actually arrives needs a real DSN: with `SENTRY_DSN` set, run
`bundle exec rails runner 'Sentry.capture_message("morph.io Sentry test")'`
and check the event appears in the Sentry project.





### SQLite copy and Elasticsearch reindex (#1589)

The specs drive the rsync runner and Elasticsearch with doubles, plus one real
copy between temporary directories. These need real servers, so they run on the
rehearsal server and are recorded with each dry run. The commands are in
`docs/sqlite_and_search_migration.md`.

- Run `app:sqlite_migration:bulk` from the old server to the rehearsal
  server's shared data directory (for example `/srv/www/data/scrapers`), and record the elapsed time and transfer speed it prints.
  Run it again and check it only transfers what changed.
- Run `app:sqlite_migration:delta` with `DELETE=1 MAX_DELETE=N` after a change and a
  deletion on the source, then compare the two file listings with
  `app:sqlite_migration:verify`.
- Run `app:search_migration:reindex` against Elasticsearch 8.19 and check the
  counts match, then search for a scraper and a person on the site.
