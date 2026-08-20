# Morph.io Comprehensive Upgrade Path

Status: Accepted
Last updated: 20 August 2026

This document is the single plan of record for bringing morph.io onto supported
versions of its operating system, database, application stack and scraper
build system (Buildstep). It consolidates the strategy from the
[software versions epic (#1351)](https://github.com/openaustralia/morph/issues/1351),
the work already merged, the work in flight, and the open issues across
[openaustralia/morph](https://github.com/openaustralia/morph),
[openaustralia/buildstep](https://github.com/openaustralia/buildstep) and
[openaustralia/infrastructure](https://github.com/openaustralia/infrastructure).
The hard-to-reverse decisions underpinning it are recorded as ADRs in
[`docs/adr/`](../docs/adr/); the 20 August 2026 revision resolved the
previously deferred decisions marked in §7.

## 1. Executive summary

Almost every layer of morph.io is past end of life:

| Layer | Current | Status | Target |
|---|---|---|---|
| OS (production) | Ubuntu 16.04 LTS (Xenial) | Security support ended April 2021 | Ubuntu 24.04 LTS (Noble), supported to April 2029 |
| Database | MySQL 5.7.33, mixed latin1/utf8mb3 encodings | EOL October 2023 | MySQL 8.0 (Canonical-maintained in 24.04 `main`), utf8mb4 throughout |
| Redis | 3.0.6 (production) | EOL ~2018, known RCEs | Redis 7.x (24.04 package) |
| Ruby | 2.7.6 | EOL March 2023 | Ruby 3.4.x, supported to March 2028 |
| Rails | 6.0.6.1 | Security support ended June 2023 | Rails 8.1.x, security support to October 2027 |
| Docker Engine (host) | 20.10.7 | EOL; seccomp profile breaks modern images (clone3) | Current Docker Engine from Docker's noble repository |
| Buildstep | cedar-14 default; heroku-18; heroku-24 image exists but scrapers fail | cedar-14/heroku-18 stacks EOL and unbuildable | Working heroku-24 platform as the default; old stacks removed |
| Elasticsearch | 7.17.6 | Maintenance mode | Keep 7.17 through migration; ES 8.x/OpenSearch decision deferred (§7) |
| Error tracking | Honeybadger (limits exhausted) + NewRelic (broken agent install) | — | Sentry (sponsored plan) + OTel |

The strategy (from #1351, revised 15 August 2026): upgrade Rails in small
verified hops, keep every other component supported at least as long as the
Rails version in use, and use versions recommended for each Rails release.
Rails 7.2's security support ended 09 August 2026 and Rails 8.0's ends
07 November 2026, so both are stepping stones only; **Rails 8.1 + Ruby 3.4 +
Ubuntu 24.04 is the resting point.**

The clock is the old server's accumulated risk, not an external deadline:
**cutover (Phase 5) targets mid-November 2026**, three months from this
revision, with a week-8 go/no-go checkpoint (§5). If the checkpoint fails,
the date moves; the scope does not.

Three hard constraints dictate the sequencing:

1. **The current production server cannot go past Ruby 3.0.7.** rvm 1.29.3 on
   the box cannot update itself or install newer rubies. Rails hops up to 7.1
   (which supports Ruby 3.0) can be deployed to the current server; everything
   beyond requires a rebuilt server.
2. **Buildstep heroku-24 cannot work on the current server.** Docker 20.10.7's
   seccomp profile returns `EPERM` instead of `ENOSYS` for the `clone3`
   syscall, breaking glibc >= 2.34 images such as heroku-24's Ubuntu 24.04
   base ([#1473](https://github.com/openaustralia/morph/issues/1473)).
   Upgrading the host Docker Engine is the fix; the workarounds in
   [buildstep#5](https://github.com/openaustralia/buildstep/pull/5) and
   [buildstep#7](https://github.com/openaustralia/buildstep/pull/7) are
   interim measures at best.
3. **The new server cannot go below Ruby 3.1.** Ruby 3.0 and older do not
   build against OpenSSL 3, which is all Ubuntu 24.04 ships. The new server
   therefore runs Ruby 3.4 from day one, the Ruby 3.0.7 → 3.4 hop happens
   *before* cutover (verified on the rehearsal server, Phase 4d), and no
   application state ever needs to run on both servers: rollback during
   cutover is a DNS flip back to the untouched old server, not a redeploy
   ([ADR 0005](../docs/adr/0005-ruby-3-4-only-on-the-new-server.md)).

The new server is therefore the lynchpin. It will be provisioned from the
**openaustralia/infrastructure repository** (Terraform + Ansible), not from
`morph/provisioning`, closing
[infrastructure#341](https://github.com/openaustralia/infrastructure/issues/341)
and bringing morph in line with how PlanningAlerts, RightToKnow and
TheyVoteForYou are managed
([ADR 0002](../docs/adr/0002-provision-the-new-server-from-the-infrastructure-repository.md)).
The new server stays on **Linode** (agreed with OAF ops, 20 August 2026):
outbound IP reputation matters for a scraping workload, and AWS ranges are
widely blocked by anti-bot services
([ADR 0004](../docs/adr/0004-stay-on-linode-for-the-server-migration.md)).
Once cutover is complete, `morph/provisioning`
is removed and the morph repository retains application deployment
(Capistrano) only.

A decision has already been made that morph will **not** be replaced with a
simpler AWS-native system (openaustralia/oaf-internal#308 — rejected). This
plan upgrades morph in place
([ADR 0001](../docs/adr/0001-upgrade-morph-in-place.md)).

### Phase overview

| Phase | What | Where it runs | Depends on |
|---|---|---|---|
| 0 | Baseline: CI green, security gem bumps, deprecation guard | current server | — (done) |
| 1 | #1438 fix; Sentry gem; Rails 6.0 → 6.1 | current server | 0 |
| 2 | Rails 6.1 → 7.0 + Ruby 3.0.7 | current server | 1 |
| 3 | Rails 7.0 → 7.1 | current server | 2 |
| 4 | New Ubuntu 24.04 rehearsal server via infrastructure repo; Ruby 3.4 app verification; disk cleanup | rehearsal server | can start in parallel with 1–3 |
| 5 | Data migration (MySQL 8.0 + utf8mb4), cutover at Ruby 3.4, decommission old server | both | 3 + 4 |
| 6 | Rails 7.2 → 8.0 → 8.1; gem unblocks | new server | 5 |
| 7 | Buildstep heroku-24 working; old stacks deprecated; examples updated | new server | 5 (host Docker); can prepare earlier |
| 8 | Observability (OTel, Honeybadger retirement), backup monitoring, ancillary devops | new server | 5 |

Phases 1–3 (application) and Phase 4 (infrastructure) are independent tracks.
In practice they are interleaved rather than truly parallel: Phase 1 goes to
production first (momentum, and it de-risks every later hop), then Phase 4a
porting starts while Phase 1 soaks. Phase 7 preparation (buildstep image
work, example scrapers, scraperwiki python3 branch) can also start before
Phase 5, but final verification needs the new Docker host.

## 2. Current state assessment

### 2.1 Application

- Rails 6.0.6.1, Ruby 2.7.6 (`.ruby-version`, `Gemfile`), Sorbet typing
  (RBIs must be regenerated with `bundle exec tapioca gem` on every gem
  change), RSpec suite with some known-flaky Docker-dependent tests.
- Deployment: Capistrano + rvm (`config/deploy.rb` pins
  `rvm_ruby_version 2.7.6`), system foreman 0.63 (gem pinned to match),
  nginx + Passenger, Faye for live updates, Sidekiq for background jobs.
- Local development: `docker-compose.yml` (MySQL 5.7.33, Redis 3.2,
  Elasticsearch 7.17.7 in `docker_images/services.yaml`), forced
  `linux/amd64` because Sorbet has no Linux ARM64 build.

Gems pinned by out-of-date infrastructure or Rails, to be unpinned at the
phase indicated:

| Gem | Pin | Reason | Unblocked in |
|---|---|---|---|
| `sidekiq` | `~> 5` | Production Redis 3.x | Phase 6 (after Redis 7) |
| `psych` | `>= 3.3.4, < 4` | Rails 6.0 incompatible with Psych 4 | Phase 1 (Rails 6.1) |
| `foreman` | `0.63.0` | Matches system `ruby-foreman` package on Xenial | Phase 4/5 (new server) |
| `omniauth-github` | `~> 1.4.0` | Needs fix only in 1.4; omniauth 2 migration outstanding | Phase 6 |
| `octokit` | `~> 4.0` | API changes in later majors | Phase 6 |
| `faraday` / `nokogiri` floors | — | Remaining CVE fixes need Ruby >= 3.0 | Phase 2+ (tracked in oaf-internal#316) |
| `annotaterb` | `~> 4.15.0` | 4.16+ requires Ruby 3.0 | Phase 2 |
| `render_sync` | OpenAustralia fork | Upstream unmaintained | Phase 6 (replace or vendor) |

### 2.2 Production infrastructure

- Linode `g6-standard-8` (32 GB RAM / 640 GB disk), Ubuntu 16.04, defined in
  `terraform/morph/` of the **infrastructure repo** (instance + Cloudflare
  DNS already under Terraform; image pinned by hand-built history).
- Provisioned by `morph/provisioning` (Ansible): mysql (distro `state=latest`),
  redis (distro package), ruby (rvm from get.rvm.io), docker-ce from the
  *xenial* Docker repo, nginx-passenger, mitmproxy, Discourse
  (help.morph.io), certbot, backups (recently extended with duply→S3 for
  scraper repos and Discourse, PRs #1500/#1501). The playbook still
  bootstraps Python 2 for Ansible.
- Vagrant + VirtualBox (`ubuntu/xenial64`) for infra development; Ansible
  Galaxy role installs are broken
  ([#1340](https://github.com/openaustralia/morph/issues/1340)).
- Database encoding is inconsistent: tables are a mix of latin1 and
  utf8/utf8mb3, columns differ between production and a freshly migrated
  development database
  ([#1494](https://github.com/openaustralia/morph/issues/1494)), and 4-byte
  UTF-8 (emoji) in scraper output causes production errors
  ([#1453](https://github.com/openaustralia/morph/issues/1453)).
- Disk: ~402 GB used; 132 GB MySQL (126 GB `log_lines`), ~117 GB stale
  `data.sqlite` files, 91 GB Docker. Cleanup could allow halving or
  quartering the server size
  ([#1459](https://github.com/openaustralia/morph/issues/1459)).

### 2.3 Buildstep

Repository: <https://github.com/openaustralia/buildstep> (issues disabled —
all tracking happens in openaustralia/morph under the `buildpacks` label).
Images are published to Docker Hub/GHCR by GitHub Actions on push to `main`.

| Platform | Base | State |
|---|---|---|
| `cedar-14` | herokuish (cedar) | **Default platform in morph** (`Morph::DockerRunner::DEFAULT_PLATFORM`); Dockerfile no longer builds (#1335); Heroku runtime downloads gone (#1344) |
| `heroku-18` | herokuish (heroku-18) | Dockerfile no longer builds (#1334); requested runtimes unavailable (#1344); stack EOL |
| `heroku-24` | `gliderlabs/herokuish:v0.10.3-24` | Image builds and is enabled in morph (`PLATFORMS`, PR #1452), but scrapers fail on production: clone3/seccomp (#1473), Ruby buildpack bootstrap failure "File name too long" (#1464), no Python 2 (#1450/#1451) |

Example scrapers were updated to heroku-24 then reverted to heroku-18
(PRs #1455/#1456) because nothing ran on production. Usage priority for
getting heroku-24 working, from
[#1476](https://github.com/openaustralia/morph/issues/1476):
Ruby (750 scrapers running daily) > Python (255) > PHP (63) > Node.js (18) >
Perl (5). PHP, Node and Perl are candidates to drop if they cost too much
effort.

Open buildstep PRs: [#5](https://github.com/openaustralia/buildstep/pull/5)
(force sequential DNS) and [#7](https://github.com/openaustralia/buildstep/pull/7)
(clone3-workaround) — both compensate for the old host Docker and should be
re-evaluated once the host is upgraded (§Phase 7).

### 2.4 Work already done

- Rails 5.2 → 6.0 upgrade merged and deployed (PR #1409 and the "Merge
  round 1" series), including Zeitwerk, yarn provisioning (#1406), separate
  service logs (#1420), extra tests (#1421/#1437), model/route annotations
  (#1433).
- `upgrade/00-*` preparation series merged (August 2026): CI/Brakeman fixes
  (#1495), gems at latest Ruby 2.7-compatible patches (#1496), dead Active
  Storage config removed (#1497), **tests raise on Rails deprecation
  warnings** (#1498).
- Backups: DB backup rake task (#1398), `log_lines` trim (#1397), duply→S3
  for Discourse (#1500) and scraper git repos (#1501).
- heroku-24 added to buildstep (buildstep#4) and enabled in morph (#1452);
  GHCR push fixed (buildstep#9); build-only CI for PRs (buildstep#6).
- Database encoding groundwork: development encoding settled (#1493).
- Rubocop config unified (#1503); deploy git tags (#1479).
- Non-breaking security gem bumps merged (#1489, 18 August 2026).
- AGENTS.md agent guidance merged (#1504, 18 August 2026).
- Repository cleanup series for #1506 merged (PRs #1507, #1509, #1510,
  #1511): dead app code and unused gems removed, support file drift and
  README alignment fixed. Issue #1506 itself remains open.

### 2.5 In flight / stale

- **Stale upgrade branches** (PRs closed, branches kept): `chore/rails_61`
  (PR #1423, 116 commits behind main), `chore/rails_70_and_ruby_30`
  (PR #1424, 241 behind), `chore/rails_71` (PR #1425, 241 behind). These
  contain substantial completed work and should be **mined, not rebased**
  (see Phase 1 for why); delete each branch once its phase has mined it.
- **Open buildstep PRs #5 and #7** — hold until Phase 7 decision.
- Remaining CVEs needing Ruby/Rails upgrades are tracked in
  oaf-internal#316.

## 3. Phased upgrade path

### Phase 0 — Baseline (complete)

Goal: a trustworthy base to upgrade from.

1. ~~Merge PR #1489 (security gem bumps). Regenerate Sorbet RBIs.~~ Done,
   18 August 2026.
2. Confirm CI is green including Brakeman and bundle-audit; keep the
   deprecation-raise guard from #1498 active so each Rails hop surfaces its
   deprecations in the test run rather than in production.
3. Triage remaining bundle-audit findings into "fixed by Phase N" notes
   (oaf-internal#316).

Exit criteria met as of 18 August 2026: CI and Brakeman green on `main`;
no bundle-audit findings other than those explicitly deferred to later
phases.

### Phase 1 — Precursors, Sentry, Rails 6.0 → 6.1 (current server)

Closes #1355's predecessor step; issue tracking: epic #1351.

Two small standalone PRs land before the Rails work:

1. **#1438 (unsafe sign-out redirect):** a small security fix that should
   not share a diff with a framework bump.
2. **Sentry gems** (advances #1474, moved forward from Phase 8): add
   sentry-ruby/sentry-rails alongside Honeybadger. Honeybadger's limits are
   already exhausted, and with no staging environment (see below) Sentry is
   the soak instrument for every hop that follows. OTel, monitoring scope
   and Honeybadger removal stay in Phase 8.

Then the Rails hop:

3. **Mine `chore/rails_61`, do not rebase it.** Stripped of regenerable
   noise (RBIs, schema.rb, lockfiles) the branch is roughly 15 substantive
   changes, and a wholesale rebase would reintroduce Active Storage
   migrations that #1497 deliberately removed. Mining list: the Gemfile
   bump, `add_template_helper` → `helper` in `AlertMailer`, the
   `errors.keys` replacement in `Domain`, and the spec adjustments. Skip
   its spring workaround (`main` is on spring 4, which should have the
   fix — verify) and its Active Storage migrations. Delete the branch once
   mined.
4. Run `rails app:update` fresh, then adopt the 6.1 defaults in a single
   PR with one commit per flag in `new_framework_defaults_6_1.rb`, ending
   with `config.load_defaults 6.1`. The suite plus the deprecation guard
   vets each flag; per-flag commits keep bisectability. The only flag
   needing real thought is `cookies_same_site_protection = :lax` — the
   GitHub OAuth callback is a top-level redirect so Lax is fine, but verify
   sign-in explicitly after deploy.
5. Unpin `psych` (Rails 6.1 carries the Psych 4 fix).
6. Regenerate RBIs; fix deprecations until the guard passes.
7. Deploy to production in a low-usage window. **There is no staging
   environment** (dev.morph.io has no DNS record), so Phases 1–3 deploy
   straight to production: `cap production deploy:rollback` is the
   fallback, Sentry is the monitor, and each hop soaks about a week before
   the next.

### Phase 2 — Rails 6.1 → 7.0 + Ruby 3.0.7 (current server)

Issues: [#1355](https://github.com/openaustralia/morph/issues/1355),
[#1356](https://github.com/openaustralia/morph/issues/1356).

1. Mine `chore/rails_70_and_ruby_30` for completed work (cookie
   serialization hybrid→json migration is already done there).
2. Ruby 2.7 → 3.0.7: keyword-argument separation fixes; 3.0.7 is already
   installed on the production server so no server change is needed.
   Update `.ruby-version`, `Gemfile`, `config/deploy.rb`
   (`rvm_ruby_version`), CI and the development `Dockerfile`
   (`FROM ruby:3.0.7`).
3. Rails 7.0: check ActiveAdmin compatibility (historically lags); Sprockets
   continues to work (do not adopt the new asset pipeline defaults).
4. Unpin `annotaterb`; bump `faraday`/`nokogiri` floors now allowed by
   Ruby 3.0.
5. Deprecation guard clean; production deploy in a low-usage window,
   rollback point kept, one week soak on Sentry.

### Phase 3 — Rails 7.0 → 7.1 (current server)

Issue: [#1358](https://github.com/openaustralia/morph/issues/1358).

1. Mine `chore/rails_71` (as in Phase 1: mine, do not rebase; delete the
   branch after); `rails app:update`; adopt 7.1 defaults.
2. Stay on Ruby 3.0.7: this is the last application state that deploys to
   the **current** production server, and Ruby 3.0 is also the ceiling that
   server can run.
3. Deprecation guard clean; production deploy in a low-usage window,
   rollback point kept, one week soak on Sentry.

Rails 7.1 supports Ruby 3.0 through 3.4, which makes it the bridge for the
server migration — but not because the same state must run on both servers.
It never does: the old server tops out at Ruby 3.0.7 and the new server
starts at Ruby 3.4
([ADR 0005](../docs/adr/0005-ruby-3-4-only-on-the-new-server.md)), and
rollback during cutover is a DNS flip to the untouched old server, not a
redeploy. The bridge is the *codebase*: one Rails version that runs on both
Rubies, so the Ruby 3.4 change is the only app-tier difference at cutover.

### Phase 4 — New Ubuntu 24.04 server, provisioned from openaustralia/infrastructure

Issues: morph [#1374](https://github.com/openaustralia/morph/issues/1374),
[#1362](https://github.com/openaustralia/morph/issues/1362),
[#1352](https://github.com/openaustralia/morph/issues/1352),
[#1357](https://github.com/openaustralia/morph/issues/1357),
[#1361](https://github.com/openaustralia/morph/issues/1361),
[#1459](https://github.com/openaustralia/morph/issues/1459),
[#1382](https://github.com/openaustralia/morph/issues/1382);
infrastructure [#341](https://github.com/openaustralia/infrastructure/issues/341).

**4a. Move provisioning to the infrastructure repository (infrastructure#341).**
morph is the last OAF service provisioned from its own repo. Port
`morph/provisioning` into `openaustralia/infrastructure`:

- Reuse the existing shared roles in `roles/internal/` — `base-server`,
  `mysql`, `deploy-user`, `oaf.backup`, `oaf.certbot`, `awscloudwatch`,
  `remove_rvm`/`remove_rbenv`/`remove_mise` — instead of morph's bespoke
  equivalents (`mysql`, `deploy-user`, `backups`, `certbot`, `ruby`).
- Port the genuinely morph-specific roles: `morph-app`, `mitmproxy`,
  `docker-server` (rewritten for the noble Docker repo and current Docker
  Engine), `nginx-passenger`, `discourse`, `redis`, `swapfile`.
- Targets for the new roles: MySQL 8.0 (Canonical-maintained in 24.04
  `main` — no need for 8.4/9.x, see the analysis in #1351), Redis 7.x from
  the 24.04 archive (#1361: verify the distro version suffices before
  reaching for 7.2 from redis.io), Node.js LTS, Python 3 only (drop the
  python2 Ansible bootstrap), `/srv/www` layout consistently (#1382).
- Ruby: **keep rvm**, installed current via the infrastructure repo's
  existing external `rvm.ruby` role, exactly as `theyvoteforyou` (Ruby
  3.4.4) and `planningalerts` (Ruby 3.3.4) already run it. The fleet has
  not converged on a replacement: `openaustralia` uses rbenv, and mise
  support is half-built (its install role is commented out in `site.yml`
  and a `remove_mise` role exists to purge it). morph's pain was a frozen
  2017 rvm on Xenial, not rvm itself. `capistrano-rvm` stays; install
  Ruby 3.4 only
  ([ADR 0005](../docs/adr/0005-ruby-3-4-only-on-the-new-server.md)).
- Secrets move into the shared infrastructure Ansible Vault (morph's
  `ansible.cfg` already uses the same vault password file).
- Align with infrastructure repo initiatives while porting: Ansible version
  upgrade (infrastructure#574) and the Terraform → OpenTofu migration
  (infrastructure#580).

**4b. Terraform the new machine** in `terraform/morph/` (the current Linode
instance and Cloudflare DNS are already there). **Hosting is decided**
(20 August 2026, agreed with OAF ops): the new server stays on **Linode**.
The deciding factor is outbound IP reputation for a scraping workload — AWS
ranges are widely blocked by anti-bot services, and moving could silently
degrade hundreds of scrapers in ways no rehearsal would reveal
([ADR 0004](../docs/adr/0004-stay-on-linode-for-the-server-migration.md)).
This also makes the RDS question (#1375) moot. Size the new machine *after*
4c — the goal in #1459 is to halve or quarter the current 32 GB/640 GB
instance.

**4c. Disk cleanup on the current server (before migration, #1459):**
trim `log_lines` aggressively and add the cron task (#1403), prune Docker
(#1124 considerations), identify stale `data.sqlite` files and long-broken
auto-run scrapers (#1380) for archival/removal with owner notification.
Less data means a cheaper server and a much shorter cutover window.

**4d. Build the rehearsal server first** (#1352): provision a box with the
new playbooks whose job is rehearsing everything before production depends
on it — provisioning, the Ruby 3.4 app, data migration and cutover. From
here on it is the staging environment this project otherwise lacks.

- Deploy the Phase 3 app (Rails 7.1) to it at **Ruby 3.4**: this is where
  the Ruby 3.0.7 → 3.4 hop (#1359) happens and is verified — keyword-arg
  separation was already done in Phase 2, so expect mostly RBI churn,
  stdlib gem extractions and Ruby 3.x strictness fixes. Update
  `.ruby-version`, `Gemfile`, `config/deploy.rb`, CI and the development
  `Dockerfile`; regenerate all Sorbet RBIs. Note that landing
  the Ruby 3.4 change on `main` ends deployability to the old server (its
  ceiling is 3.0.7), so merge it only once the rehearsal server has
  validated it, shortly before cutover; until then it lives on a branch
  deployed to the rehearsal server only.
- Run the full test/verification suite there, including buildstep heroku-24
  smoke tests (this is where #1473 is expected to disappear thanks to the
  new Docker Engine).

**4e. Decommission plan for morph-repo provisioning:** once production
cutover (Phase 5) completes, remove `provisioning/`, `Vagrantfile`,
`ansible.cfg` and the Makefile ansible targets from the morph repo; update
README/TESTING to point infra work at the infrastructure repo (its
Vagrant/Packer tooling replaces morph's xenial Vagrant box, resolving the
Ansible-galaxy part of #1340). The morph repo keeps Capistrano deployment
and local docker-compose development only.

### Phase 5 — Data migration, cutover, decommission

Issues: [#1453](https://github.com/openaustralia/morph/issues/1453),
[#1494](https://github.com/openaustralia/morph/issues/1494),
[#1357](https://github.com/openaustralia/morph/issues/1357);
infrastructure [#266](https://github.com/openaustralia/infrastructure/issues/266).

1. **Schema/encoding normalisation (do it once, during the move):** convert
   the whole database to `utf8mb4`/`utf8mb4_unicode_ci` as part of the
   5.7 → 8.0 dump/restore, following the approach in #1453 (new database
   with correct defaults, migrate data in, swap names). Set explicit
   `charset`/`collation` in the provisioned `database.yml` (#1494) so
   schema.rb is identical between production and development ever after
   ([ADR 0003](../docs/adr/0003-mysql-8-and-utf8mb4-once-during-the-move.md)).
2. Verify against MySQL 8.0 in CI/dev first: bump
   `docker_images/services.yaml` (mysql 8.0, redis 7.x) so the local stack
   matches the new server; run the suite; fix any 8.0 issues (sql_mode,
   `GROUP BY`, reserved words e.g. `groups`, auth plugin for `mysql2`).
3. **Cutover runbook** (rehearse fully on the rehearsal server):
   - Pre-sync bulk data (scraper `data.sqlite` files, git repos, Docker
     images that survive cleanup) with rsync; iterate until delta is small.
   - Maintenance page on; stop queues (Sidekiq quiet → drain); final
     `mysqldump --single-transaction` → load into 8.0 with utf8mb4; final
     rsync delta; reindex Elasticsearch (searchkick reindex) on the new box.
   - Deploy app via Capistrano to the new server at Ruby 3.4 + Rails 7.1
     (the Ruby hop was validated on the rehearsal server, Phase 4d); run
     smoke checks (§6); flip DNS (Cloudflare, already in Terraform); watch
     error rates in Sentry.
   - Rollback: DNS back to the old server, which is left untouched (read-only
     data divergence is the accepted cost within the cutover window; keep
     the window short and schedule in low-usage hours).
4. Keep the old Linode for a defined grace period (e.g. 2 weeks), then
   decommission, execute 4e (remove morph-repo provisioning), and downsize
   confirmation for #1459.
5. Wire backup completion monitoring to Slack (infrastructure#266) and
   confirm the long-broken SQL backup to S3 is verified working end-to-end
   (#1392) on the new machine.

### Phase 6 — Rails 7.2 → 8.0 → 8.1 (new server)

Issues: [#1359](https://github.com/openaustralia/morph/issues/1359) (done
in Phase 4d/5),
[#1360](https://github.com/openaustralia/morph/issues/1360) (retarget to
8.1 per revised epic), epic #1351.

1. **Ruby 3.0.7 → 3.4.x** (#1359): already done — it moved to Phase 4d/5
   because Ruby 3.0 cannot run on the new server at all
   ([ADR 0005](../docs/adr/0005-ruby-3-4-only-on-the-new-server.md)). Ruby
   4.0 exists but no Rails release is tested against it — stay on 3.4.
2. **Rails 7.1 → 7.2.3.x** (brief hop; support already ended):
   `app:update`, defaults, deprecation-clean. Do not linger.
3. **Rails 7.2 → 8.0.5.x** (stepping stone; support ends Nov 2026): check
   ActiveAdmin and gems against the 8.0 removals list (enum keyword args,
   deprecated-parameters flags). Sprockets and Sidekiq/Redis keep working —
   Propshaft and Solid Queue defaults only affect new apps; no forced
   migration.
4. **Rails 8.0 → 8.1.3.x** (resting point; support to Oct 2027): check the
   removals called out in #1351 (`bin/rake stats`, SQLite3 `:retries`,
   MySQL unsigned column helpers, query-string parsing changes).
5. **Gem unblocks along the way:**
   - `sidekiq` 5 → 7/8 (Redis 7 now available); review
     `sidekiq-limit_fetch` compatibility or replace with native queue
     limits.
   - `omniauth`/`omniauth-github` → 2.x (CSRF-safe request phase; update
     Devise integration).
   - `octokit` → current major; drop the direct `faraday` workaround if the
     underlying issue is gone.
   - `foreman` unpin (new server no longer uses the Xenial system package —
     or replace foreman with systemd units in the provisioning port).
   - Replace or retire `render_sync` fork (evaluate Turbo/ActionCable-based
     replacement for the live-run views; Faye is also a candidate for
     retirement in the same pass).
   - `elasticsearch`/`searchkick`: keep 7.17 client against ES 7.17; ES 8.x
     is a deferred decision (§7).
6. After each hop: RBI regen, deprecation-guard-clean test run, soak on
   the rehearsal server (the staging environment from Phase 4d onward),
   production deploy. The Rails guide's advice (good coverage before
   8.x) is satisfied by the coverage work in #1437/#1436 — extend where
   gaps are found rather than blocking on a coverage number.

### Phase 7 — Buildstep: working heroku-24, retire old stacks

Repository: <https://github.com/openaustralia/buildstep> (changes land
there; tracking stays in morph issues).
Issues: [#1476](https://github.com/openaustralia/morph/issues/1476),
[#1473](https://github.com/openaustralia/morph/issues/1473),
[#1464](https://github.com/openaustralia/morph/issues/1464),
[#1450](https://github.com/openaustralia/morph/issues/1450),
[#1443](https://github.com/openaustralia/morph/issues/1443)–
[#1448](https://github.com/openaustralia/morph/issues/1448),
[#1451](https://github.com/openaustralia/morph/issues/1451),
[#1462](https://github.com/openaustralia/morph/issues/1462),
[#1334](https://github.com/openaustralia/morph/issues/1334),
[#1335](https://github.com/openaustralia/morph/issues/1335),
[#1344](https://github.com/openaustralia/morph/issues/1344),
[#1336](https://github.com/openaustralia/morph/issues/1336),
[#1337](https://github.com/openaustralia/morph/issues/1337).

1. **Re-test heroku-24 on the new Docker host** (rehearsal server from 4d). The
   clone3/seccomp failure class (#1473) should be resolved by the current
   Docker Engine. Then re-evaluate the open workaround PRs: buildstep#7
   (clone3-workaround) and buildstep#5 (sequential DNS) — merge only if a
   failure mode remains on the new host; otherwise close with an
   explanation. If production cutover is still months away and scraper
   breakage is acute, merging them as *interim* mitigation for the old host
   is acceptable, but they must be reverted after Phase 5.
2. **Keep the base current:** bump `Dockerfile.heroku-24` to the latest
   `gliderlabs/herokuish` release tag for heroku-24 whenever touched;
   refresh Chrome + matching chromedriver pins; keep the mitmproxy CA cert
   handling as documented in the buildstep README.
3. **Ruby on heroku-24** (#1464, highest priority per #1476): fix the
   buildpack bootstrap failure ("Failed to download a Ruby executable for
   bootstrapping" / "File name too long") — verify the herokuish-bundled
   Ruby buildpack version supports heroku-24's S3 layout, and stop morph
   stripping `BUNDLED WITH` from Gemfile.lock so modern Bundler versions
   work (morph-side change in the app build code).
4. **Python on heroku-24** (#1446/#1450/#1451/#1462): Python 3 only.
   Publish/adopt the python3 branch of scraperwiki-python (#1450); document
   that python2 is unsupported on heroku-24 (#1451); make missing
   `requirements.txt` default sanely instead of attempting a python2
   scraperwiki install (#1205).
5. **Example scrapers and language support decision** (#1443–#1448): update
   Ruby and Python examples to heroku-24 with current runtimes and verify
   they run end-to-end on the rehearsal server; then decide per #1476 whether PHP,
   Node.js and Perl are worth fixing (63/18/5 daily scrapers respectively)
   or get deprecation notices and removal from the supported-languages
   documentation.
6. **Flip the default and deprecate old stacks** (morph-side):
   `DEFAULT_PLATFORM` cedar-14 → heroku-24 in
   `app/lib/morph/docker_runner.rb`; notify owners of scrapers still
   pinned to cedar-14/heroku-18 (site banner + email), with a published
   migration guide (#1223 documentation of platform choice); after a
   deprecation window, remove `cedar-14`/`heroku-18` from `PLATFORMS` and
   delete `Dockerfile.cedar-14`/`Dockerfile.heroku-18` from buildstep
   (#1334/#1335 close as won't-fix-by-removal).
7. **Docs**: how to run buildstep locally (#1339), updated platform docs
   (#1223, #1451).

### Phase 8 — Observability and ancillary upgrades

Issues: [#1474](https://github.com/openaustralia/morph/issues/1474),
[#1480](https://github.com/openaustralia/morph/issues/1480),
[#1210](https://github.com/openaustralia/morph/issues/1210),
[#1392](https://github.com/openaustralia/morph/issues/1392),
[#1403](https://github.com/openaustralia/morph/issues/1403);
infrastructure [#363](https://github.com/openaustralia/infrastructure/issues/363).

1. **Sentry** (#1474): the sentry-ruby/sentry-rails gems have been running
   alongside Honeybadger since Phase 1 (upgrade phases are exactly when
   error tracking matters most). Here: OTel configuration provisioned via
   the infrastructure repo roles or Rails credentials (#1480), decide cron
   and APM monitoring scope per the discussion on #1474, then remove the
   `honeybadger` gem.
2. **Drop the NewRelic infrastructure agent** from provisioning — it has
   never installed cleanly (#1210) and is superseded by the Sentry/OTel and
   CloudWatch patterns in the infrastructure repo.
3. **Backups verified and monitored**: S3 SQL backup working (#1392),
   completion pings to Slack (infrastructure#266), restore drill documented
   and performed once on the rehearsal server.
4. **Recurring DB hygiene** as cron (#1403): `log_lines` trim, sqlite
   vacuum after runs (#1215), docker prune policy that doesn't bust caches
   (#1124).
5. Email/DNS hygiene while DNS is being touched anyway: morph.io DMARC
   policy (infrastructure#363, #364).

## 4. Risk register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Stale rails_6x/7x branches conflict heavily with 8 months of main | High | Medium | Mine them for decisions (cookie serializer, app:update choices) rather than rebasing wholesale; redo mechanical parts |
| utf8mb4 conversion corrupts or truncates data (index length limits, latin1-stored-as-utf8 mojibake) | Medium | High | Dump/restore into a fresh DB rather than in-place ALTER; verify row counts + checksums per table; spot-check known-emoji rows; rehearse on the rehearsal server with a production dump |
| MySQL 8.0 behaviour changes break queries (sql_mode, reserved words, auth plugin) | Medium | Medium | Run full suite + rehearsal-server soak against 8.0 (Phase 5 step 2) before cutover |
| heroku-24 still broken for some failure mode after Docker upgrade | Medium | High for scraper users | Rehearsal-server smoke tests per language before any comms; keep heroku-18 image runnable (even if unbuildable) until heroku-24 verified; buildstep PRs #5/#7 held as fallback |
| Cutover window data divergence (scrapers writing during migration) | Medium | Medium | Quiet queues + maintenance page; pre-sync so final delta is minutes; schedule low-usage window |
| ActiveAdmin / Devise / omniauth lag behind Rails 8.x | Medium | Medium | Check compatibility matrix before each hop; these gems historically follow within a minor version — pin and wait rather than fork |
| Sorbet friction on every hop (RBI churn, runtime checks) | High | Low | `tapioca gem` regeneration is a scripted step in each phase's checklist; treat RBI-only diffs as mechanical |
| Rails hops deployed to production without a staging soak (no staging environment exists) | Medium | Medium | Small verified hops; deprecation guard; low-usage deploy windows; `cap production deploy:rollback`; Sentry (installed Phase 1) watched for a week per hop |
| Ruby 3.4 jump at cutover widens the app-tier delta | Medium | Medium | Rails 7.1 codebase is the bridge (supports Ruby 3.0–3.4); the Ruby hop is validated on the rehearsal server before `main` takes it; rollback stays a DNS flip |
| Scraper-owner backlash at platform deprecation | Medium | Medium | Deprecation window with banner + email, migration guide, and #1476's data on how few scrapers use PHP/Node/Perl |
| Key-person risk (upgrade knowledge concentrated in one contributor) | Medium | High | This document; PRs kept small and phase-scoped; decisions recorded in §7 |

## 5. Verification checkpoints

Every phase must pass before the next begins:

1. `bundle exec rspec` green in CI (including the Docker-dependent tests on
   a runner with Docker; known-flaky tests fixed or quarantined explicitly,
   #1436).
2. Zero Rails deprecation warnings (enforced by the #1498 guard).
3. `bundle-audit` / Brakeman clean or explicitly waived with a phase noted.
4. Sorbet: `srb tc` clean after RBI regeneration.
5. Soak. For Phases 1–3 this is a **production soak**: deploy in a
   low-usage window, keep the Capistrano rollback point, watch Sentry for
   about a week (no staging environment exists — dev.morph.io has no DNS
   record). From Phase 4d the **rehearsal server** takes this role, and the
   checklist is: sign-in via GitHub, create scraper, run scraper on each
   supported platform, view live log (Faye), download data, API query,
   webhook delivery, admin interface, Sidekiq queues draining, Discourse
   up.
6. For server/DB phases additionally: backup + restore drill, error-tracker
   quiet for 48h post-deploy, per-table row-count/checksum comparison after
   data migration.
7. For buildstep: the Ruby and Python example scrapers run end-to-end on
   heroku-24 on the rehearsal server *and* production before any
   deprecation comms go out.
8. **Week-8 go/no-go (target: mid-October 2026):** if the rehearsal server
   has not completed a full cutover rehearsal by eight weeks into the
   three-month window, the cutover date moves. Scope does not — every §7
   deferral has already stripped the plan to essentials, and descoping
   would only create a second migration later.

## 6. Issue and PR mapping

| Phase | Closes / advances |
|---|---|
| 0 | morph PR #1489; parts of oaf-internal#316 |
| 1 | epic #1351 (6.1 step); #1438; advances #1474 (Sentry gems); supersedes PR #1423 branch |
| 2 | #1355, #1356; supersedes PR #1424 branch |
| 3 | #1358; supersedes PR #1425 branch |
| 4 | #1374, #1362, #1352, #1361, #1382, #1459 (with 5), #1359 (with 5), #1210; infrastructure#341, advances infrastructure#574/#580; parts of #1340 |
| 5 | #1453, #1494, #1357, #1392 (verify), #1403; infrastructure#266 |
| 6 | #1360 (retargeted to 8.1), remainder of epic #1351; sidekiq/omniauth/octokit/render_sync TODOs in Gemfile |
| 7 | #1476, #1473, #1464, #1450, #1451, #1443, #1444, #1445, #1446, #1447, #1448, #1462, #1344, #1334, #1335, #1336, #1337, #1205, #1339, #1223; buildstep PRs #5, #7 (merge-or-close decision) |
| 8 | #1474, #1480, #1210 (removal), #1392, #1403; infrastructure#363, #364 |

Issues **not** covered by this plan (functional bugs/features — triage
separately): the large backlog of enhancement/bug issues (e.g. #1461,
#1457, #1454, #1465, #1469 and older). One exception already bundled:
**#1438 (unsafe sign-out redirect)** is a small security fix picked up as a
standalone PR at the start of Phase 1 rather than waiting.

### Zenhub tracking

This mapping is mirrored in Zenhub (OpenAustralia Foundation workspace)
as issue types, parent/child relationships and blocking dependencies:

- **#1351 is typed Project** and is the top-level container.
- **Phase epics** (typed Epic, children of #1351): #1362 (Phase 4 — new
  server), #1453 (Phase 5 — DB migration/UTF-8), #1476 (Phase 7 —
  working heroku-24, with #1462 python-support epic and #1443 example
  scrapers epic nested), #1443 (example scrapers, with #1444–#1448 as
  GitHub sub-issues).
- **Rails/Ruby hop tasks** (#1355, #1356, #1358, #1359, #1360) and #1438
  are direct children of #1351, ordered by blocking dependencies
  (#1356→#1355→#1358→#1359; #1362 blocks #1359/#1360/#1476/#1443).
- **Blocking dependencies** also record: #1352 and infrastructure#341
  block #1362; #1357 and #1352 block #1453; #1450 blocks #1446.
- **Pre-existing hierarchies preserved** (linked by dependency instead of
  re-parenting): #1474 stays under the org-wide Sentry epic
  (oaf-internal#235) with #1480 as its child; #1392 stays under
  infrastructure#212 (backups); #1403 stays under #1373; #1375 stays
  under #1374; infrastructure#341 stays under infrastructure#503.

## 7. Deferred decisions

Record the outcome of each of these in this document when made. Three were
resolved in the 20 August 2026 revision and are marked **Decided**:

| Decision | Options | When needed | Notes |
|---|---|---|---|
| Hosting for the new server | **Decided (20 Aug 2026, with OAF ops): stay on Linode** | Phase 4b | Outbound IP reputation for a scraping workload was the deciding factor; AWS ranges are widely blocked by anti-bot services ([ADR 0004](../docs/adr/0004-stay-on-linode-for-the-server-migration.md)). Revisit if fleet-tooling benefits ever outweigh continuity. |
| Managed database | **Moot while hosting stays Linode** (#1375) | — | Was only meaningful if AWS had been chosen. |
| Postgres (#1058) | Stay MySQL vs migrate | Not in this plan | Explicitly out of scope; utf8mb4 MySQL 8 is the target. Revisit after Rails 8.1. |
| Search | ES 7.17 vs ES 8.x vs OpenSearch | After Phase 6 | searchkick 5 supports all three; 7.17 is safe through this plan. |
| PHP / Node.js / Perl support | Fix on heroku-24 vs deprecate | Phase 7 step 5 | Usage data in #1476. |
| Ruby version manager on servers | **Decided (20 Aug 2026): keep rvm**, installed current via the infrastructure repo's `rvm.ruby` role | Phase 4a | Fleet majority (theyvoteforyou, planningalerts); no OAF convergence exists to follow — mise is half-built and only openaustralia uses rbenv. morph's pain was a frozen 2017 rvm on Xenial, not rvm itself. |
| Live-updates stack | Keep Faye/render_sync vs Turbo Streams/ActionCable | Phase 6 step 5 | render_sync fork is unmaintained; scope carefully — it touches core UX. |
| Cron/APM monitoring scope in Sentry | Errors only vs cron vs APM | Phase 8 | Depends on sponsored plan quotas (#1474 discussion). The Sentry gems themselves land in Phase 1. |

## 8. References

- [Architecture decision records](../docs/adr/) — the hard-to-reverse
  decisions behind this plan (upgrade in place, provisioning home, MySQL
  8.0 + utf8mb4, Linode, Ruby 3.4-only new server)
- [Epic #1351 — Update Morph Software versions](https://github.com/openaustralia/morph/issues/1351)
  (strategy, version research, support dates — revised 15 Aug 2026)
- [Rails upgrade guide](https://guides.rubyonrails.org/upgrading_ruby_on_rails.html)
- [Ruby/Rails compatibility table](https://www.fastruby.io/blog/ruby/rails/versions/compatibility-table.html)
- [endoflife.date/rails](https://endoflife.date/rails),
  [endoflife.date/ruby](https://endoflife.date/ruby),
  [endoflife.date/ubuntu](https://endoflife.date/ubuntu)
- [openaustralia/buildstep](https://github.com/openaustralia/buildstep)
- [openaustralia/infrastructure](https://github.com/openaustralia/infrastructure)
  (`terraform/morph/`, `roles/internal/`, issue #341)
- clone3/seccomp background: [#1473](https://github.com/openaustralia/morph/issues/1473),
  [AkihiroSuda/clone3-workaround](https://github.com/AkihiroSuda/clone3-workaround)
