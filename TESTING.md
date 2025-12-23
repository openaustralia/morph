TESTING
=======

If you're running guard (see above) the tests will also automatically run when you change a file.

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




