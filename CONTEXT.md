# morph.io

morph.io runs scrapers for people. A scraper is a program in someone's GitHub
repository. morph.io builds it into a container, runs it on a schedule or on
demand, and serves whatever it writes back out through a web UI and an API.

This file is a glossary and nothing else. Standing guidance for working in the
repository is in [`AGENTS.md`](./AGENTS.md).

## Language

### People and accounts

**Owner**:
A GitHub account morph.io knows about, either a User or an Organization. Named
for owning scrapers, but used wherever an account is referenced, including
collaborators, so an Owner does not necessarily own anything.
_Avoid_: account, profile

**User**:
An Owner that is a person, and the only kind of Owner that can sign in.
_Avoid_: member

**Organization**:
An Owner that is a GitHub organisation. Holds scrapers but never signs in.
_Avoid_: org, team, group

**Collaborator**:
An Owner granted permissions on a Scraper's repository, mirrored from GitHub.
_Avoid_: contributor, which is a different thing

**Contributor**:
A User who appears in the commit history of a Scraper's repository, taken from
GitHub.
_Avoid_: collaborator, author

**Supporter**:
A User or Organization paying to fund morph.io.
_Avoid_: customer, subscriber, sponsor

### Scrapers

**Scraper**:
A program in a GitHub repository that morph.io runs, together with everything
morph.io keeps about it. Refers to the repository and the record
interchangeably.
_Avoid_: crawler, bot, job, spider

**Language**:
The one supported language a Scraper is written in: Ruby, Python, PHP, Perl or
JavaScript. Determined by which scraper file the repository contains.
_Avoid_: runtime, stack

**Variable**:
A named secret value morph.io passes into a Scraper's environment when it runs.
Every name begins `MORPH_`.
_Avoid_: secret value, env var, setting, config

**Auto run**:
The setting that has morph.io run a Scraper on a schedule rather than only when
someone asks.
_Avoid_: cron, scheduled, automatic

**Broken scraper**:
A Scraper whose most recent Run finished with an error. Drives what an Alert
reports.
_Avoid_: failing, failed, erroring

### Running

**Run**:
One execution of scraper code in a container, together with its Log lines and
the record of what it changed in the Data.
_Avoid_: job, build, scrape, execution

**Remote Run**:
A Run of code uploaded from someone's own machine rather than fetched from a
repository. Has no Scraper, and its Data is discarded when it finishes.
_Avoid_: local run, CLI run, ad hoc run

**Log line**:
One line a Scraper wrote to stdout or stderr during a Run, streamed live to
anyone watching the page.
_Avoid_: output, console line, message

**Slot**:
One unit of capacity to hold a Run. The number of Slots caps how many Runs
happen at once. Note that the setting controlling this is named
`maximum_concurrent_scrapers` but counts Runs.
_Avoid_: worker, queue place, concurrency limit

### Data and delivery

**Data**:
The rows a Scraper has written, as people query and download them through the
API.
_Avoid_: dataset, results, output

**Scraper database**:
The SQLite file holding one Scraper's Data.
_Avoid_: bare "database", which is ambiguous with morph.io's own MySQL
database, the datastore, the dump

**Webhook**:
A URL morph.io posts to when a Scraper's Run finishes, so another system can
react.
_Avoid_: callback, hook, notification

### Watching

**Watch**:
A standing subscription by a User to hear about a Scraper, or about every
Scraper an Owner has.
_Avoid_: alert, which is the email, subscription, follow

**Watcher**:
A User who holds a Watch.
_Avoid_: subscriber, follower

**Alert**:
The email sent to a Watcher covering the Broken scrapers they watch, and the
ones that have recovered.
_Avoid_: notification, digest, warning

### Traffic

**Domain**:
A site a Scraper made requests to, recorded so people can see what a Scraper
scrapes and find scrapers by the sites they cover. Never morph.io's own domain,
and unrelated to "domain" in the domain-modelling sense.
_Avoid_: site, host, target

**Connection log**:
A record that a Run made a request to a Domain, captured from the proxy the
Run's traffic passes through.
_Avoid_: request log, access log
