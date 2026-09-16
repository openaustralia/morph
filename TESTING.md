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

### GitLab integration

`spec/lib/morph/gitlab_client_integration_spec.rb` runs against gitlab.com for
real and skips itself unless two variables are set:

    GITLAB_TEST_GROUP=openaustralia-morph-test
    GITLAB_TEST_TOKEN=glpat-...

Setting that up is a one-off human step:

1. Create a gitlab.com group (OAF uses `openaustralia-morph-test`).
2. In it, create a public project `public-scraper` and a private project
   `private-scraper`, each with a README so they have a default branch.
3. As an Owner of the group, create a personal access token with `read_api`
   and put it in `GITLAB_TEST_TOKEN`. It is only read; nothing is created.

`Morph::GitSync` (cloning and fetching over https with a token) is `:nocov:`
like the GitHub equivalent it was lifted from. To check it by hand, add a
scraper from a GitLab project and run it: the run page should show the
commit revision and the scraper's code link should open on GitLab.

### GitLab credential tiers

Connecting an Organization's GitLab group (the "GitLab access" panel on the
Organization page) tries a group access token, then a group deploy token,
then falls back to your sign-in. Check each tier by connecting a group on a
Free-plan account (expect a deploy token) and one on Premium or Ultimate
(expect a group access token), and that the panel's wording changes.

### app:backup and app:restore rake tasks

Testing restore is too hard to automate. 

### Error reporting to Sentry

Automated tests only cover the SDK staying quiet when `SENTRY_DSN` is unset.
That an event actually arrives needs a real DSN: with `SENTRY_DSN` set, run
`bundle exec rails runner 'Sentry.capture_message("morph.io Sentry test")'`
and check the event appears in the Sentry project.




