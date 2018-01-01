[![Stories in Ready](https://badge.waffle.io/openaustralia/morph.png?label=ready)](https://waffle.io/openaustralia/morph) [![Build Status](https://travis-ci.org/openaustralia/morph.png?branch=master)](https://travis-ci.org/openaustralia/morph) [![Code Climate](https://codeclimate.com/github/openaustralia/morph.png)](https://codeclimate.com/github/openaustralia/morph) [![Dependency Status](https://gemnasium.com/badges/github.com/openaustralia/morph.svg)](https://gemnasium.com/github.com/openaustralia/morph)

## morph.io: A scraping platform

* A [Heroku](https://www.heroku.com/) for [Scrapers](https://en.wikipedia.org/wiki/Web_scraping)
* All code and collaboration through [GitHub](https://github.com/)
* Write your scrapers in Ruby, Python, PHP, Perl or JavaScript (NodeJS, PhantomJS)
* Simple API to grab data
* Schedule scrapers or run manually
* Process isolation via [Docker](https://www.docker.com/)
* Trivial to move scraper code and data from [ScraperWiki Classic](https://classic.scraperwiki.com/)
* Email alerts for broken scrapers

### Dependencies
Ruby 2.3.1, Docker, MySQL, SQLite 3, Redis, mitmproxy.
(See below for more details about installing Docker)

Development is supported on Linux and Mac OS X.

### Repositories

User-facing:

* [openaustralia/morph](https://github.com/openaustralia/morph) - Main application
* [openaustralia/morph-cli](https://github.com/openaustralia/morph-cli) - Command-line morph.io tool
* [openaustralia/scraperwiki-python](https://github.com/openaustralia/scraperwiki-python) - Fork of [scraperwiki/scraperwiki-python](https://github.com/scraperwiki/scraperwiki-python) updated to use morph.io naming conventions
* [openaustralia/scraperwiki-ruby](https://github.com/openaustralia/scraperwiki-ruby) - Fork of [scraperwiki/scraperwiki-ruby](https://github.com/scraperwiki/scraperwiki-ruby) updated to use morph.io naming conventions

Docker images:
* [openaustralia/buildstep](https://github.com/openaustralia/buildstep) - Base image for running scrapers in containers

### Installing Docker

#### On Linux

Just follow the instructions on the [Docker site](https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/).

Your user account should be able to manipulate Docker (just add your user to the `docker` group).

#### On Mac OS X

Install [Docker for Mac](https://docs.docker.com/docker-for-mac/install/).

### Starting up Elasticsearch

Morph needs Elasticsearch to run. We've made things easier for development by using docker
to run Elasticsearch.

    docker-compose up

### To Install Morph

    bundle install
    cp config/database.yml.example config/database.yml
    cp env-example .env

Edit `config/database.yml` with your database settings

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

### Running tests

If you're running guard (see above) the tests will also automatically run when you change a file.

By default, RSpec will skip tests that have been tagged as being slow. To change this behaviour, add the following to your `.env`:

    RUN_SLOW_TESTS=1

By default, RSpec will run certain tests against a running Docker server. These tests are quite slow, but not have been tagged as slow. To stop Rspec from running these tests, add the following to your `.env`:

    DONT_RUN_DOCKER_TESTS=1

#### Guard Livereload

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

### Deploying to production

This section will not be relevant to most people. It will however be relevant if you're deploying to a production server.

#### git-encrypt

We're using [git-encrypt](https://github.com/shadowhand/git-encrypt) to encrypt certain files, like the private key for the SSL certificate.

To make this work you have to do some [special things](https://github.com/shadowhand/git-encrypt/tree/legacy#decrypting-clones) _before_ you clone the morph repository:

```
# install old version of git-encrypt
npm -g install git-encrypt
gitcrypt version # should equal "0.3.0"

# clone the repo
git clone -n https://github.com/openaustralia/morph
cd morph

# set up gitcrypt
git config gitcrypt.salt 'YOUR_SALT'
git config gitcrypt.pass 'YOUR_STRONG_PASSKEY'
git config gitcrypt.cipher aes-256-ecb
git config filter.encrypt.smudge "gitcrypt smudge"
git config filter.encrypt.clean "gitcrypt clean"
git config diff.encrypt.textconv "gitcrypt diff"
```

If you intend to make changes to the production infrastructure, you'll need real values for `gitcrypt.salt` and `gitcrypt.pass`.

Please [create a GitHub issue](https://github.com/openaustralia/morph/issues/new) and we'll start the conversation.

#### Production devops development

Install [Vagrant](http://www.vagrantup.com/), [VirtualBox](https://www.virtualbox.org) and [Ansible](http://www.ansible.com/).

Install the hostsupdater plugin: `vagrant plugin install vagrant-hostsupdater`

Run `vagrant up local`. This will build and provision a box that looks and acts like production at `dev.morph.io`.

Once the box is created and provisioned, deploy the application to your Vagrant box:

    cap local deploy

Now visit https://dev.morph.io/

#### Production provisioning and deployment

To deploy morph.io to production, normally you'll just want to deploy using Capistrano:

    cap production deploy

When you've changed the Ansible playbooks to modify the infrastructure you'll want to run:

    ansible-playbook --user=root --inventory-file=provisioning/hosts provisioning/playbook.yml

#### SSL certificates

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

##### Installing certificates for local vagrant build

    sudo certbot certonly --manual -d dev.morph.io --preferred-challenges dns -d api.dev.morph.io -d faye.dev.morph.io -d help.dev.morph.io

### How to contribute

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

### Copyright & License

Copyright OpenAustralia Foundation Limited. Licensed under the Affero GPL. See LICENSE file for more details.
