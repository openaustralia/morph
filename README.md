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

### Support for Developers / CI

Docker compose is used to provide redis, elasticsearch and mysql services as required for dev and CI
(use SERVICES to specify which services to start if you don't want them all).

vagrant is used to provide a local staging environment to test ansible provisioning and capistrano app deployment.

If you don't want to set up ruby on your local host and/or have a different enough docker / mysql / redis version
then `cd /vagrant` within a `vagrant ssh` session to work on the files mapped in from the project root.

## Installing Docker

Install either a supported version of [Docker Engine](https://docs.docker.com/engine/install/)
for Ubuntu Linux or [Docker Desktop](https://docs.docker.com/desktop/) for macOS/X or MS Windows
which includes Docker Engine.

On Linux, Your user account should be able to manipulate Docker (just add your user to the `docker` group).

## Installing Vagrant

Install [VirtualBox](https://www.virtualbox.org/) os other supported virtualization provider.

Then install [Vagrant](https://developer.hashicorp.com/vagrant)

## Make targets

Various make targets have been added to for developer convenience when developing on the local host:

* help - This help dialog.
* vagrant-up - launch local vagrant VM
* vagrant-provision - Provision local vagrant VM using ansible
* vagrant-deploy - Deploy app to local vagrant VM
* services-up - Run up services with persistent data (use SERVICES="redis elasticsearch" to exclude mysql)
* services-down - Close down services required for CI / development
* services-logs - View logs for services (use SERVICES='elasticsearch redis' for specific services)
* services-status - Check status of services

* test - Run rspec tests
* lint - Lint code
* share-web - Share web server on port 3000 to the internet
* clean - Clean out venv, installed roles and rails tmp/cache
* clobber - Remove everything including logs
* docker-clean - Remove all Docker resources INCLUDING databases in volumes

targets to use docker compose rather than vagrant for a full development environment (BETA):

* docker-up - Full Docker environment including ruby containers (persistent data) BETA

targets for production:

* production-provision - Provision production using ansible
* production-deploy - Deploy app to production

Morph needs various services to run. We've made things easier for development by using docker
to run Elasticsearch and the other services.

    make services-up 

To stop the services use

    make services-down

To run tests use

    bin/rake db:test:prepare
    bin/rake

To get a bash shell in the running web container if you are using the full docker environment:

    docker compose exec web bash -i

To run commands in a temporary container rather than the currently running container, use instead

    docker compose run web --rm -it bash -i


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

Note - morph builds a docker image using these buildstep images combined with the config files from the scraper to
build a separate docker image for each scraper with all the dependencies ready to go.

### Tunnel GitHub webhook traffic back to your local development machine

We use "ngrok" a tool that makes tunnelling internet traffic to a local development machine easy. 

First [download ngrok](https://ngrok.com/download) if you don't have it already. Then,

    make share-web
    # rune: ngrok http 3000

Make note of the ngrok forwarding url (`*.ngrok-free.dev`).

<!-- TODO: Add instructions for debugging and working with callbacks for the GitHub app in development with https://webhook.site -->

### Creating Github Application

You'll need to create an application on GitHub So that morph.io can talk to GitHub. 
We've pre-filled most of the important fields for a few different configurations below:

* [Create GitHub application on your personal account for use in development, port 3000](https://github.com/settings/apps/new?name=Morph.io+(development)&description=Get+structured+data+out+of+the+web&url=http://127.0.0.1:3000&callback_urls[]=http://127.0.0.1:3000/users/auth/github/callback&setup_url=http://127.0.0.1:3000&setup_on_update=true&public=true&webhook_active=false&administration=write&contents=write&emails=read)
* [Create GitHub application on your personal account for use in production](https://github.com/settings/apps/new?name=Morph.io&description=Get+structured+data+out+of+the+web&url=https://morph.io&callback_urls[]=https://morph.io/users/auth/github/callback&setup_url=https://morph.io&setup_on_update=true&public=true&webhook_active=false&webhook_url=https://morph.io/github/webhook&administration=write&contents=write&emails=read)
* [Create GitHub application on the openaustralia organization for use in production](https://github.com/organizations/openaustralia/settings/apps/new?name=Morph.io&description=Get+structured+data+out+of+the+web&url=https://morph.io&callback_urls[]=https://morph.io/users/auth/github/callback&setup_url=https://morph.io&setup_on_update=true&public=true&webhook_active=false&webhook_url=https://morph.io/github/webhook&administration=write&contents=write&emails=read)

You will need to add and change a few values manually:
* Disable "Expire user authorization tokens"
* Select "Any Account" if you are demoing with a team
* Add extra callback urls:
  * http://0.0.0.0:3000/users/auth/github/callback  # if you click on the url puma lists on start up
  * <forwarding url noted above>/users/auth/github/callback
  * Change the port for the local urls if you are not using the default port 3000 for the rails app
* Add an image - you can use the standard logo at `app/assets/images/logo.png` (you can add this after the app is created)
* If the webhooks are active and being used in production (currently not the case) then you'll also need to 
  * add a "Webhook secret" for security.
  * add a "Webhook URL" - the ngrok url with `/github/webhook` on the end

Next you'll need to fill in some values in the `.env` file which come from the GitHub App that you've just created.

* `GITHUB_APP_ID` - Look for "App ID" near the top of the page. This should be an integer
* `GITHUB_APP_NAME` - Look for "Public link". The name is what appears after "https://github.com/settings/apps/". 
  It's essentially a url happy version of the name you gave the app.
* `GITHUB_APP_CLIENT_ID` - Look for "Client ID" near the top of the page.
* `GITHUB_APP_CLIENT_SECRET` - Go to "Generate a new client secret".
* `GITHUB_APP_INSTALLED_BY` - A user that has installed the app (used by tests)

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

## Testing

See [TESTING.md](TESTING.md) for automated and manual testing instructions.

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

## Rubymine specific advice

### Disable Spring in RubyMine:

Under Run → Edit Configurations → your RSpec configuration,
set Environment variable: DISABLE_SPRING=1

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

## Branch naming

To aid readbility, please use the following naming convention:

* feature/: For developing new features.
* bugfix/: For addressing bugs in the existing codebase.
* hotfix/: For urgent bug fixes in the production environment, typically branched directly from the stable or main branch.
* refactor/: For code refactoring efforts.
* docs/: For changes related to documentation.
* chore/: For maintenance, dependency updates, tooling changes, and other non-feature work.

# Copyright & License

Copyright OpenAustralia Foundation Limited. Licensed under the Affero GPL. See LICENSE file for more details.
