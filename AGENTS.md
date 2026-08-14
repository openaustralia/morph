# AGENTS.md

This file provides guidance to AI coding agents (Claude Code, GitHub Copilot,
and others) when working with code in this repository.

## What this repository is

`openaustralia/morph` is the Rails application behind [morph.io](https://morph.io),
OAF's scraping platform for developers. People point it at a GitHub repository
containing a scraper, and morph.io builds a Docker image for that scraper, runs
it on a schedule or on demand, captures its stdout and stderr as log lines,
stores whatever the scraper writes into a per-scraper SQLite database, and
serves that data back out through a web UI and an API.

The pieces that make this more than a CRUD app all live in `app/lib/morph/`:

- `Morph::Runner` is the high level entry point. Given a `Run` it synchronises
  the scraper's git repo, runs it, streams log lines back to the browser via
  render_sync, and records the result. Concurrency is capped by
  `SiteSetting.maximum_concurrent_scrapers`, counted by labelling containers
  and asking Docker how many exist, not by a queue length.
- `Morph::DockerRunner` and `Morph::DockerUtils` do the actual container work,
  building each scraper's image on top of the
  [openaustralia/buildstep](https://github.com/openaustralia/buildstep) base
  images plus whatever dependency files the scraper repo provides
  (`default_files/` holds the fallbacks used when a scraper does not supply
  its own).
- `Morph::Database` and `Morph::SqliteDiff` own the per-scraper SQLite file.
  Scraper output is a SQLite database on disk, not rows in the main MySQL
  database.
- `Morph::Github` and `Morph::GithubAppInstallation` wrap the GitHub App used
  for authentication, repo access and repo creation.
- `Morph::Language` maps a scraper repo to a supported language (Ruby, Python,
  PHP, Perl, JavaScript) and to the right default files.

Background work runs through Sidekiq (`app/workers/`, queues `default` and
`scraper` per `config/sidekiq.yml`). Search is Elasticsearch via searchkick.
Live log streaming is faye plus render_sync (`sync.ru`, the `faye` process in
`Procfile`). Outbound scraper traffic is logged by a mitmproxy container
(`docker_images/morph-mitmdump/`) which calls back into the API. The admin
interface is ActiveAdmin under `/admin`.

Scraper git repos and their SQLite databases live under `db/scrapers/`, which
is gitignored and is a Capistrano `linked_dir` in production. It is live data,
not build output. Do not clean it out to fix a problem.

## Setting up

Copy the three example files before anything else, because none of them are in
git and Rails will not boot without the first one:

```sh
cp config/database.yml.example config/database.yml
cp env-example .env
cp env-staging-example .env.vagrant   # only if provisioning vagrant
```

Services (MySQL, Redis, Elasticsearch) run in Docker:

```sh
make services-up      # SERVICES="redis elasticsearch" to skip MySQL
make services-down
make services-status
```

`README.md` has the full walkthrough for creating the GitHub App and filling in
the `GITHUB_APP_*` values in `.env`. The private key it tells you to save to
`config/morph-github-app.private-key.pem` is what gates the GitHub-integration
specs, so tests behave differently depending on whether you did that step.

## Running the tests

There are three test profiles, and which one you want depends on what you are
about to claim:

```sh
make quick-tests   # excludes docker and GitHub specs. Fast feedback.
make ci-tests      # same exclusions as GitHub Actions. Run before taking a PR out of draft.
make all-tests     # everything, including the slow Docker integration specs.
make test          # quick-tests then all-tests
```

Three environment variables control what gets skipped, and `spec/spec_helper.rb`
sets them itself when the prerequisites are missing:

- `RUN_SLOW_TESTS=1` opts *in* to specs tagged `:slow`. Without it they are
  excluded.
- `DONT_RUN_DOCKER_TESTS=1` excludes specs tagged `:docker`. These are also
  excluded automatically if `docker info` fails.
- `DONT_RUN_GITHUB_TESTS=1` excludes specs tagged `:github`. These are also
  excluded automatically if `GITHUB_APP_INSTALLED_BY` is unset or
  `config/morph-github-app.private-key.pem` is missing.

CI (`.github/workflows/ruby.yml`) runs with all three of
`DONT_RUN_DOCKER_TESTS=1 RUN_SLOW_TESTS=1 DONT_RUN_GITHUB_TESTS=1`, which is
what `make ci-tests` reproduces. A green `make quick-tests` therefore does not
mean CI will pass.

To run one file or one example:

```sh
bundle exec rspec spec/models/scraper_spec.rb
bundle exec rspec spec/models/scraper_spec.rb -e "some description"
```

### Coverage thresholds are hardcoded per profile

`spec/spec_helper.rb` sets a different `SimpleCov.minimum_coverage` for each
profile: 77.09 for `quick-tests`, 80.05 for `ci-tests`, 87.02 for `all-tests`.
If you add or remove code and coverage moves, the run fails on the threshold
rather than on a spec, and you have to update the matching number by hand.
Update only the one for the profile you actually ran, and say in the pull
request why it moved.

Thresholds are skipped entirely when you pass specific spec files or
`--example`, so a passing single-file run tells you nothing about coverage.

### VCR, WebMock and Docker do not mix

`spec/spec_helper.rb` switches behaviour on example metadata: `:docker` turns
VCR off and allows real network access, `:webmock` turns VCR off and disallows
it, and everything else must wrap its HTTP calls in `VCR.use_cassette`.
Cassettes live in `spec/fixtures/vcr_cassettes`.

Two deliberate workarounds in there are easy to undo by accident, and both fail
silently rather than loudly:

- `WebMock::HttpLibAdapters::ExconAdapter.disable!` is required or streaming
  output from a Docker container buffers instead of streaming.
- The `:webmock` branch must not be wrapped in `WebMock.enable!` /
  `WebMock.disable!`, which breaks the Docker and VCR specs.

## Linting and type checking

Both linters gate CI, and `make lint` runs both:

```sh
bundle exec rubocop
bundle exec haml-lint
```

Views are checked by haml-lint rather than RuboCop, which is why RuboCop's
Sorbet cops exclude `app/views/**/*`.

This codebase is typed with [Sorbet](https://sorbet.org). `Sorbet/StrictSigil`
is enabled in `.rubocop.yml`, so new Ruby files under `app/` and `lib/` need
`# typed: strict` and full `sig` blocks. The exclusions are `app/admin/*`,
`spec/**/*`, `sync.ru` and views, which are `# typed: false`. Files also carry
`# frozen_string_literal: true`.

After changing any gem version, regenerate the RBI files, as the Gemfile's own
header says:

```sh
bundle exec tapioca gem
```

Schema annotations are regenerated by annotaterb, which hooks into the `db:`
rake tasks in development unless `ANNOTATERB_SKIP_ON_DB_TASKS` is set (see
`lib/tasks/annotate_rb.rake`). `.annotaterb.yml` sets `exclude_factories`,
`exclude_fixtures` and `exclude_tests` to false, so a single migration rewrites
comment blocks in models, factories and specs alike. Expect those churned
comment blocks in the diff and commit them.

## Version pins that look stale but are not

The application runs Ruby 2.7.6 and Rails 6.0.6.1, so do not reach for Ruby 3.x
syntax. Several gems are pinned for reasons recorded in `Gemfile` comments, and
bumping them without dealing with the underlying cause will break production:

- `sidekiq "~> 5"`, because production is still on redis 3.x.
- `psych >= 3.3.4, < 4`, until the Rails 6.1 upgrade lands.
- `annotaterb "~> 4.15.0"`, because 4.16 requires Ruby 3.0.
- `foreman "0.63.0"`, to match the system foreman package on production.
- `jquery-ui-rails "~> 5"`, because newer versions raise
  `Sprockets::FileNotFound`.
- `omniauth-github "~> 1.4.0"` and a fork of `render_sync`, both pinned to
  carry fixes.

Check for security updates with `bundle exec ruby-audit` and
`bundle exec bundle-audit`, or via the repository's Dependabot alerts.

## Apple Silicon

`docker-compose.yml` forces `platform: linux/amd64` for the Ruby containers
because Sorbet has no Linux ARM64 build. On Apple silicon you must switch on
"Use Rosetta for x86/amd64 emulation on Apple Silicon" in Docker Desktop, and
containers will be slow.

`make docker-clean` runs `docker system prune -af --volumes`, which destroys
the MySQL and Elasticsearch volumes as well as the images. Use `make
services-down` unless you actually mean to lose the databases.

## Contributing

This repository has no `CONTRIBUTING.md`, so the org-wide one applies:
[`openaustralia/.github/.github/CONTRIBUTING.md`](https://github.com/openaustralia/.github/blob/main/.github/CONTRIBUTING.md).
It is the authority on branching, pull requests, sign-off and AI disclosure.
The pull request and issue templates are inherited from that repository too,
so they will not be found locally.

In short: branch off `main` using the
[Conventional Branch](https://conventionalbranch.org/#summary) form
`type/issue-number-short-description`, open the pull request as a draft early,
assign it to yourself, take it out of draft only once the checks in
`.github/workflows/` pass, and sign off every commit with `git commit -s`.

**`README.md` contradicts the org guide in two places, and the org guide wins.**
Its "How to contribute" section describes a fork-and-pull-request flow rather
than branching off `main`, and its "Branch naming" section uses `docs/` where
the org guide uses `doc/`. Neither README section mentions the DCO sign-off.

`.github/CODEOWNERS` in this repository requests reviews. Note that a review is
about understanding the change together, not gatekeeping it.

## Conventions specific to this org

- Non-partisan: nothing in this repository should imply endorsement or
  criticism of any party, candidate or position.
- Australian English throughout.
- No em dashes. Use a hyphen, a comma or a full stop.
- Disclose AI involvement in both places the org `CONTRIBUTING.md` asks for: an
  `Assisted-by: <agent-name>:<model-id>` trailer on each commit, and a note in
  the pull request description. Report the model actually used, not a
  remembered default. A human, not an agent, signs off the commit.
- `README.md` sets coding standards worth honouring beyond RuboCop: keep
  methods short, keep files under about 400 lines, and comment why rather than
  what. `spec/models/scraper_spec.rb` is the worked example of splitting a file
  that got too big.
- Code that cannot be covered automatically is marked `# :nocov:` and listed in
  `TESTING.md` as a manual test. If you add such code, add it there too.

## Known rough edges

- `README.md` links to `doc/docker_development_commands.md`, which does not
  exist in this repository.
- `config/routes.rb` wraps `devise_for` in a `Owner.table_exists?` check so
  that migrations can run against a database without the table. Adding routes
  near that block needs care.
- `.rubocop_todo.yml` is inherited by `.rubocop.yml` and holds a backlog of
  accepted offences. Prefer fixing an offence over widening the todo file.
