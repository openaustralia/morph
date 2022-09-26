[![Build Status](https://travis-ci.com/openaustralia/morph.png?branch=master)](https://travis-ci.com/openaustralia/morph) [![Code Climate](https://codeclimate.com/github/openaustralia/morph.png)](https://codeclimate.com/github/openaustralia/morph)

# morph.io: A scraping platform

* A [Heroku](https://www.heroku.com/) for [Scrapers](https://en.wikipedia.org/wiki/Web_scraping)
* All code and collaboration through [GitHub](https://github.com/)
* Write your scrapers in Ruby, Python, PHP, Perl or JavaScript (NodeJS, PhantomJS)
* Simple API to grab data
* Schedule scrapers or run manually
* Process isolation via [Docker](https://www.docker.com/)
* Trivial to move scraper code and data from [ScraperWiki Classic](https://classic.scraperwiki.com/)
* Email alerts for broken scrapers

## Dependencies
Ruby, Docker, MySQL, SQLite 3, Redis, mitmproxy.
(See below for more details about installing Docker)

Development is supported on Linux (Ubuntu 20.04) and Mac OS X.

## Repositories

User-facing:

* [openaustralia/morph](https://github.com/openaustralia/morph) - Main application
* [openaustralia/morph-cli](https://github.com/openaustralia/morph-cli) - Command-line morph.io tool
* [openaustralia/scraperwiki-python](https://github.com/openaustralia/scraperwiki-python) - Fork of [scraperwiki/scraperwiki-python](https://github.com/scraperwiki/scraperwiki-python) updated to use morph.io naming conventions
* [openaustralia/scraperwiki-ruby](https://github.com/openaustralia/scraperwiki-ruby) - Fork of [scraperwiki/scraperwiki-ruby](https://github.com/scraperwiki/scraperwiki-ruby) updated to use morph.io naming conventions

Docker images:
* [openaustralia/buildstep](https://github.com/openaustralia/buildstep) - Base image for running scrapers in containers

## Installing Docker

### On Linux

Just follow the instructions on the [Docker site](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/).

Your user account should be able to manipulate Docker (just add your user to the `docker` group).

### On Mac OS X

Install [Docker for Mac](https://docs.docker.com/docker-for-mac/install/).

## Starting up Elasticsearch

Morph needs Elasticsearch to run. We've made things easier for development by using docker
to run Elasticsearch.

    docker-compose up

## To Install Morph

    bundle install
    cp config/database.yml.example config/database.yml
    cp env-example .env

Edit `config/database.yml` with your database settings

<!-- TODO: Update this for the new GitHub apps (also below they're called OAuth apps now) -->
<!-- TODO: Add instructions for debugging and working with callbacks for the GitHub app in development with https://webhook.site and https://ngrok.com/ >

Create an [application on GitHub](https://github.com/settings/applications/new) so that morph.io can talk to GitHub. Fill in the following values

* Application name: __Morph (dev)__
* Homepage URL: http://127.0.0.1:3000
* Authorization callback URL: http://127.0.0.1:3000/users/auth/github/callback
* Application description: You can leave this blank

Note the use of 127.0.0.1 rather than localhost. Use this or it won't work.

In the `.env` file, fill in the *Client ID* and *Client Secret* details provided by GitHub for the application you've just created.

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

By default, RSpec will skip tests that have been tagged as being slow. To change this behaviour, add the following to your `.env`:

    RUN_SLOW_TESTS=1

By default, RSpec will run certain tests against a running Docker server. These tests are quite slow, but not have been tagged as slow. To stop Rspec from running these tests, add the following to your `.env`:

    DONT_RUN_DOCKER_TESTS=1

### Guard Livereload

We use Guard and Livereload so that whenever you edit a view in development the web page gets automatically reloaded. It's a massive time saver when you're doing design or lots of work in the view. To make it work run

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

### Ansible Vault

We're using [Ansible Vault](https://docs.ansible.com/ansible/2.4/vault.html) to encrypt certain files, like the private key for the SSL certificate.

To make this work you will need to put the password in a
file at `~/.infrastructure_ansible_vault_pass.txt`. This is the same password as used in the [openaustralia/infrastructure](https://github.com/openaustralia/infrastructure) GitHub repository.

## Restarting Discourse

Discourse runs in a container and should usually be restarted automatically by docker.

However, if the container goes away for some reason, it can be restarted:

```
root@morph:/var/discourse# ./launcher rebuild app
```

This will pull down the latest docker image, rebuild, and restart the container.

## Production devops development

> This method defaults to creating a 4Gb VirtualBox VM, which can strain an 8Gb Mac. We suggest tweaking the Vagrantfile to restrict ram usage to 2Gb at first, or using a machine with at least 12Gb ram.

Install [Vagrant](http://www.vagrantup.com/), [VirtualBox](https://www.virtualbox.org) and [Ansible](http://www.ansible.com/).

Install a couple of Vagrant plugins: `vagrant plugin install vagrant-hostsupdater vagrant-disksize`

Install [rbenv](https://github.com/rbenv/rbenv) and [ruby-build](https://github.com/rbenv/ruby-build#readme).

If on Ubuntu, install libreadline-dev: `sudo apt install libreadline-dev libsqlite3-dev`

Install the required ruby version: `rbenv install`

Install capistrano: `gem install capistrano`

Run `make roles` to install some required ansible roles.

Run `vagrant up local`. This will build and provision a box that looks and acts like production at `dev.morph.io`.

Once the box is created and provisioned, deploy the application to your Vagrant box:

    cap local deploy

Now visit https://dev.morph.io/

## Production provisioning and deployment

To deploy morph.io to production, normally you'll just want to deploy using Capistrano:

    cap production deploy

When you've changed the Ansible playbooks to modify the infrastructure you'll want to run:

    make ansible

## SSL certificates

We're using Let's Encrypt for SSL certificates. It's not 100% automated.
On a completely fresh install (with a new domain) as root:
```
certbot --nginx certonly -m contact@oaf.org.au --agree-tos
```

It should show something like this:
```
Which names would you like to activate HTTPS for?
-------------------------------------------------------------------------------
1: morph.io
2: api.morph.io
3: faye.morph.io
4: help.morph.io
```

Leave your answer your blank which will install the certificate for all of them

### Installing certificates for local vagrant build

    sudo certbot certonly --manual -d dev.morph.io --preferred-challenges dns -d api.dev.morph.io -d faye.dev.morph.io -d help.dev.morph.io

### Scraper<->mitmdump SSL

Scapers talk out to Teh Internet by being routed through the mitmdump2
proxy container. The default container you'll get on a devops install
has no SSL certificates. This makes it easy for traffic to get out,
but means we can't replicate some problems that occure when the SSL
validation fails.

To work around this, you'll have to rebuild the mitmdump container. Look in `/var/www/current/docker_images/morph-mitmdump`; there's a `Makefile` that will aid in building the new image.

Once that's done, you'll need to build a new version of the `openaustralia/buildstep`:

* `cd`
* `git clone https://github.com/openaustralia/buildstep.git`
* `cd buildstep`
* `cp /var/www/current/docker_images/morph-mitmdump/mitmproxy/mitmproxy-ca-cert.pem .`
* `docker image build -t openaustralia/buildstep:latest .`

You should now be able to see in `docker image list --all` that your new image is ready. The next time you run a scraper it will be rebuilt using the new buildstep image.

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

We maintain a list of [issues that are easy fixes](https://github.com/openaustralia/morph/issues?labels=easy+fix&milestone=&page=1&state=open). Fixing
one of these is a great way to get started while you get familiar with the codebase.

# Copyright & License

Copyright OpenAustralia Foundation Limited. Licensed under the Affero GPL. See LICENSE file for more details.
