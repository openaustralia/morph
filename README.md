[![CI](https://github.com/openaustralia/morph/actions/workflows/ruby.yml/badge.svg)](https://github.com/openaustralia/morph/actions/workflows/ruby.yml)
[![Maintainability](https://qlty.sh/gh/openaustralia/projects/morph/maintainability.png)](https://qlty.sh/gh/openaustralia/projects/morph)

# morph.io: A scraping platform

* A [Heroku](https://www.heroku.com/) lookalike system for [Scrapers](https://en.wikipedia.org/wiki/Web_scraping)
* All code and collaboration through [GitHub](https://github.com/)
* Write your scrapers in Ruby, Python, PHP, Perl or JavaScript (NodeJS, PhantomJS)
* Simple API to grab data
* Schedule scrapers or run manually
* Process isolation via [Docker](https://www.docker.com/)
* Email alerts for broken scrapers

A development environment is provided using docker compose for the main web development container
as well as the following required services
    * elasticsearch
    * mitmproxy
    * MySQL
    * Redis

## Provisioning using Ansible

An ansible playbook is provided to provision:
- staging on a local Vagrant VM
- production

Read the [provisioning README](provisioning/README.md) for further details.

## Requirements

* A supported version of Ubuntu LTS, macOS/X or MS Windows is required.
* 8 GB of memory is the minimum, 16 GB is recommended
* SSD Disk

Docker compose is used to provide a consistent development environment.

## Installing Docker

Install either a supported version of [Docker Engine](https://docs.docker.com/engine/install/)
for Ubuntu Linux or [Docker Desktop](https://docs.docker.com/desktop/) for macOS/X or MS Windows
which includes Docker Engine.

On Linux, Your user account should be able to manipulate Docker (just add your user to the `docker` group).

## Using Docker

Morph needs various services to run. We've made things easier for development by using docker
to run Elasticsearch and the other services as well as the web container for the ruby on rails application itself.

    docker compose up --build

To stop the services then use

    docker compose down




Read [Docker Development Commands](doc/docker_development_commands.md) for a collection of useful commands.

## Initial configuration of morph development environment

    cp config/database.yml.example config/database.yml
    cp env-example .env

Edit `config/database.yml` with your database settings 
and `.env` with your local environment

Install gem requirements by running the following in the web container:

    bundle install


## Repositories

User-facing:

* [openaustralia/morph](https://github.com/openaustralia/morph) - Main application
* [openaustralia/morph-cli](https://github.com/openaustralia/morph-cli) - Command-line morph.io tool
* [openaustralia/scraperwiki-python](https://github.com/openaustralia/scraperwiki-python) - Fork of [scraperwiki/scraperwiki-python](https://github.com/scraperwiki/scraperwiki-python) updated to use morph.io naming conventions
* [openaustralia/scraperwiki-ruby](https://github.com/openaustralia/scraperwiki-ruby) - Fork of [scraperwiki/scraperwiki-ruby](https://github.com/scraperwiki/scraperwiki-ruby) updated to use morph.io naming conventions

Docker images:
* [openaustralia/buildstep](https://github.com/openaustralia/buildstep) - Base image for running scrapers in containers

### Tunnel GitHub webhook traffic back to your local development machine

We use "ngrok" a tool that makes tunnelling internet traffic to a local development machine easy. 
First [download ngrok](https://ngrok.com/download) if you don't have it already. Then,

    ngrok http 5100

Make note of the `http://*.ngrok.io` forwarding URL.

<!-- TODO: Add instructions for debugging and working with callbacks for the GitHub app in development with https://webhook.site -->

### Creating Github Application

You'll need to create an application on GitHub So that morph.io can talk to GitHub. 
We've pre-filled most of the important fields for a few different configurations below:

* [Create GitHub application on your personal account for use in development](https://github.com/settings/apps/new?name=Morph.io+(development)&description=Get+structured+data+out+of+the+web&url=http://127.0.0.1:5100&callback_urls[]=http://127.0.0.1:5100/users/auth/github/callback&setup_url=http://127.0.0.1:5100&setup_on_update=true&public=true&webhook_active=false&webhook_url=http://127.0.0.1:5100/github/webhook&administration=write&contents=write&emails=read)
* [Create GitHub application on your personal account for use in production](https://github.com/settings/apps/new?name=Morph.io&description=Get+structured+data+out+of+the+web&url=https://morph.io&callback_urls[]=https://morph.io/users/auth/github/callback&setup_url=https://morph.io&setup_on_update=true&public=true&webhook_active=false&webhook_url=https://morph.io/github/webhook&administration=write&contents=write&emails=read)
* [Create GitHub application on the openaustralia organization for use in production](https://github.com/organizations/openaustralia/settings/apps/new?name=Morph.io&description=Get+structured+data+out+of+the+web&url=https://morph.io&callback_urls[]=https://morph.io/users/auth/github/callback&setup_url=https://morph.io&setup_on_update=true&public=true&webhook_active=false&webhook_url=https://morph.io/github/webhook&administration=write&contents=write&emails=read)

You will need to add and change a few values manually:
* Disable "Expire user authorization tokens"
* Add an image - you can use the standard logo at `app/assets/images/logo.png` (you can add this after the app is created)
* If the webhooks are active and being used in production (currently not the case) then
  you'll also need to add a "Webhook secret" for security.

Next you'll need to fill in some values in the `.env` file which come from the GitHub App that you've just created.

* `GITHUB_APP_ID` - Look for "App ID" near the top of the page. This should be an integer
* `GITHUB_APP_NAME` - Look for "Public link". The name is what appears after "https://github.com/apps/". 
  It's essentially a url happy version of the name you gave the app.
* `GITHUB_APP_CLIENT_ID` - Look for "Client ID" near the top of the page.
* `GITHUB_APP_CLIENT_SECRET` - Go to "Generate a new client secret".

Also, a private key for the GitHub app is needed. 
This can be generated by clicking the "Generate a private key" button and will be automatically downloaded. 
Move and rename it to `config/morph-github-app.private-key.pem`.

Now setup the databases:

    bundle exec dotenv rake db:setup

Now you can start the server

    bundle exec dotenv foreman start

and point your browser at [http://127.0.0.1:3000](http://127.0.0.1:3000)

To get started, log in with GitHub. There is a simple admin interface
accessible at [http://127.0.0.1:3000/admin](http://127.0.0.1:3000/admin). To
access this, run the following to give your account admin rights:

    bundle exec rake app:promote_to_admin

## Running tests

If you're running guard (see above) the tests will also automatically run when you change a file.

By default, RSpec will skip tests that have been tagged as being slow. 
To change this behaviour, add the following to your `.env`:

    RUN_SLOW_TESTS=1

By default, RSpec will run certain tests against a running Docker server. 
These tests are quite slow, but not have been tagged as slow. 
To stop Rspec from running these tests, add the following to your `.env`:

    DONT_RUN_DOCKER_TESTS=1

### Guard Livereload

We use Guard and Livereload so that whenever you edit a view in development the web page gets automatically reloaded. 
It's a massive time saver when you're doing design or lots of work in the view. To make it work run

    bundle exec guard

Guard will also run tests when needed. Some tests do integration tests against a
running docker server. These particular tests are very slow. If you want to
disable them,

```
DONT_RUN_DOCKER_TESTS=1 bundle exec guard
```

### Mail in development

By default in development mails are sent to [Mailcatcher](http://mailcatcher.me/). To install

    gem install mailcatcher

## Deploying to production

This section will not be relevant to most people. It will however be relevant if you're deploying to a production server.

To deploy morph.io to production, normally you'll just want to deploy using Capistrano:

    cap production deploy

Read the [provisioning README](provisioning/README.md) for details of how to provision from updated ansible playbooks.

# How to contribute

If you find what looks like a bug:

* Check the [GitHub issue tracker](http://github.com/openaustralia/morph/issues/)
  to see if anyone else has reported issue.
* If you don't see anything, create an issue with information on how to reproduce it.

If you want to contribute an enhancement or a fix:

* Fork the project on GitHub.
* Make your changes with tests.
* Commit the changes without making changes to any files that aren't related to your enhancement or fix.
* Send a pull request.

We maintain a list of [issues that are easy fixes](https://github.com/openaustralia/morph/issues?labels=easy+fix&milestone=&page=1&state=open). 
Fixing one of these is a great way to get started while you get familiar with the codebase.

# Copyright & License

Copyright OpenAustralia Foundation Limited. Licensed under the Affero GPL. See LICENSE file for more details.
