<!-- markdown-toc start - Don't edit this section. Run M-x markdown-toc-refresh-toc -->
**Table of Contents**

- [Broad overview of architecture](#broad-overview-of-architecture)
    - [Scraper](#scraper)
    - [Sidekiq](#sidekiq)
    - [Database](#database)
    - [Frontend](#frontend)
    - [mitmproxy](#mitmproxy)
- [Current pain points and scaling challenges](#current-pain-points-and-scaling-challenges)
    - [Single machine](#single-machine)
    - [Memory contention + exponential backoff = every-growing retry queue](#memory-contention--exponential-backoff--every-growing-retry-queue)
    - [Logging overhead](#logging-overhead)
- [Footnotes](#footnotes)
    - [^2](#2)

<!-- markdown-toc end -->


# Broad overview of architecture
## Scraper
> Write your scraper in the language you know and love, push your code
> to GitHub, and we take care of the boring bits. Things like running
> your scraper regularly, alerting you if there's a problem, storing
> your data, and making your data available for download or through a
> super-simple API.

A `scraper` is a github repo[^1] with some code (and a small amount of
config) for scraping a website.

Morph injects the scraper into the
[openaustralia/buildstep](https://hub.docker.com/r/openaustralia/buildstep/)
docker image, which is based on the Herokuish environment. We've added
a `scraperwiki` library for all supported languages which contains
lots of helper code to simplify the scraping task. The code from the
Herokuish environment detects the language of the scraper; installs
the language runtime and language dependencies, and runs the script.

Console output is captured. The scraper is expected to produce an
sqlite file with the scraped data.

> Have your scraper create a SQLite database in the current working
> directory called data.sqlite. How your scraper does that and what
> tables or fields you include is entirely up to you. If there's a
> table called data then we'll show that on your scraper page first.

This SQLite file is fed back into the docker image the next time the
scraper is run, so that the scraper can create/replace/update/delete
rows as appropriate. Status about the number of rows
added/changed/deleted are stored.

## Sidekiq

Sidekiq is used as the queue runner for all parts of morph:

- Sidekiq runs the daily task which schedules scrapers randomly across
  the day[^2]
- Sidekiq runs the regular task that looks for scrapers scheduled to
  be run soon and adds them to a queue
- Sidekiq then grabs those tasks off the queue and executes them
- Sidekiq runs another job in parallel to grab the console output and
  store it
- Sidekiq runs the cleanup job that looks for stopped containers and
  cleans them up
- Sidekiq runs the jobs that clone new repos from Github

## Database

In production we use AWS RDS MySQL. DB is used to store console logs,
run history, and (I think) a permanent copy of the data from the
scraper.. as well as app settings and *handwave* the usual sorts of
stuff

## Frontend

Frontend is a ruby app. Allows users to set up a scraper from a Github
repo; manually run their scraper; supply private environment
variables; set the scraper to auto-run; add a webhook for callbacks
post-run.

Frontend also allows the user to see the console output of a scraper -
live, if it's currently running; or the stored logs from the previous
run. The live log streaming is mediated by
[Faye](https://github.com/faye/faye-websocket-ruby)

## mitmproxy

All HTTP/S traffic from the scrapers is pushed through a single
mitmproxy instance, running in Docker. This tracks which websites the
scraper scrapers (eg - [the Bega Valley
scraper](https://morph.io/planningalerts-scrapers/Bega_Valley_Applications_on_Exhibition)
`Scrapes datracker.begavalley.nsw.gov.au`)


# Current pain points and scaling challenges

## Single machine

Currently, all of Morph runs on a single Linode 32Gb VM. Obviously
this is a single point of failure; but it also means that the number
of concurrent scrapers is limited by the available RAM. Each scraper
container is capped at 512Mb and we have a limit of 30 concurrent
jobs.

## Memory contention + exponential backoff = every-growing retry queue

Until recently, this VM only had 224Gb RAM. It would relatively often
(once a month or so) get into a state where Sidekiq was unable to
schedule new tasks, because all 30 slots were full. The tasks that
couldn't be executed would be put on a retry queue. However, as time
went on, more tasks would be attempted, would fail, and would be put
on the retry queue. Each time the same task failed, Sidekiq would use
an exponential-backoff to increase the time before it was attempted
again. This would mean that if no jobs could be scheduled for a small
amount of time, a large amount of jobs would be in the retry
queue. Later on, they'd all eb retried at once and the slots would
fill; then the retry queue would get larger. This would continue until
the retry queue contained thousands of jobs, all of which had
hours-long retry times, and the queue would continue to get longer.

If caught in time, we could manually keep retrying jobs every few
minutes in order to pump them through faster than the exponential
backoff was allowing - with an eye on the capacity graphs, to make
sure we weren't retrying them too fast.

Prior to the upgrade, an early sign of impending problems was
buffers/cache dropping to 0Mb; now that we have 32Gb we consistently
have around 8-12Gb of buffers/cache in use. We haven't seen a repeat
of the spiral of death since the upgrade to 32Gb.

## Logging overhead

Currently we have to schedule and run a parallel job for every docker
container to scrape its console output and feed it to the DB and
Faye. These jobs time out, so we have to have another job which looks
for running containers without a log-scraper and start a new
log-scraping job. This could probably be avoided if we could do
something like feed the logs into syslog or some other central logging
system.

[^1]: Yes, specifically github. Login to morph is via your github
    account; scrapers are namespaced with your github username.

[^2]: Scheduling is very crude; we don't keep metrics on time taken,
    so we just scatter all the jobs across 24 hours and try to kick
    off a few every few minutes. Any job that's been running for 24
    hours is terminated.
