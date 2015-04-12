[![Stories in Ready](https://badge.waffle.io/openaustralia/morph.png?label=ready)](https://waffle.io/openaustralia/morph) [![Build Status](https://travis-ci.org/openaustralia/morph.png?branch=master)](https://travis-ci.org/openaustralia/morph) [![Code Climate](https://codeclimate.com/github/openaustralia/morph.png)](https://codeclimate.com/github/openaustralia/morph)

## Morph: A scraping platform

* A [Heroku](https://www.heroku.com/) for [Scrapers](https://en.wikipedia.org/wiki/Web_scraping)
* All code and collaboration through [GitHub](https://github.com/)
* Write your scrapers in Ruby, Python, PHP or Perl
* Simple API to grab data
* Schedule scrapers or run manually
* Process isolation via [Docker](http://www.docker.io/)
* Trivial to move scraper code and data from [ScraperWiki Classic](https://classic.scraperwiki.com/)
* Email alerts for broken scrapers

### Dependencies
Ruby 2.0.0, Docker, MySQL, SQLite 3, Redis, mitmproxy.

On OS X for development also Vagrant & VirtualBox to host a VM with Docker - see below for more.

On Linux your user account should be able to manipulate Docker (just add your user to the `docker` group).

### Repositories

User-facing:

* [openaustralia/morph](https://github.com/openaustralia/morph) - Main application
* [openaustralia/morph-cli](https://github.com/openaustralia/morph-cli) - Command-line morph tool
* [openaustralia/scraperwiki-python](https://github.com/openaustralia/scraperwiki-python) - Fork of [scraperwiki/scraperwiki-python](https://github.com/scraperwiki/scraperwiki-python) updated to use morph.io naming conventions
* [openaustralia/scraperwiki-ruby](https://github.com/openaustralia/scraperwiki-ruby) - Fork of [scraperwiki/scraperwiki-ruby](https://github.com/scraperwiki/scraperwiki-ruby) updated to use morph.io naming conventions

Buildstep docker images:
* [openaustralia/morph-docker-buildstep-base](https://github.com/openaustralia/morph-docker-buildstep-base) - Base image for buildstep
* [openaustralia/buildstep](https://github.com/openaustralia/buildstep) - Fork of [progrium/buildstep](https://github.com/progrium/buildstep) which uses the image openaustralia/morph-docker-buildstep-base as its base

Original docker images:
* [openaustralia/morph-docker-base](https://github.com/openaustralia/morph-docker-base) - Base image
* [openaustralia/morph-docker-python](https://github.com/openaustralia/morph-docker-python) - Python
* [openaustralia/morph-docker-ruby](https://github.com/openaustralia/morph-docker-ruby) - Ruby
* [openaustralia/morph-docker-perl](https://github.com/openaustralia/morph-docker-perl) - Perl
* [openaustralia/morph-docker-php](https://github.com/openaustralia/morph-docker-php) - PHP

### To Install

Running this on OSX? Read the [OSX instructions](#installing-docker-on-osx) below BEFORE doing any of this.

    bundle install
    cp config/database.yml.example config/database.yml
    cp env-example .env

Edit `config/database.yml` with your database settings

Create an [application on GitHub](https://github.com/settings/applications/new) so that Morph can talk to GitHub. Fill in the following values

* Application name: __Morph (dev)__
* Homepage URL: __http://127.0.0.1:3000__
* Authorization callback URL: __http://127.0.0.1:3000/users/auth/github/callback__
* Application description: You can leave this blank

Note the use of 127.0.0.1 rather than localhost. Use this or it won't work.

In the `.env` file, fill in the *Client ID* and *Client Secret* details provided by Github for the application you've just created.

Now setup the databases:

    bundle exec dotenv rake db:setup

Now you can start the server

    bundle exec dotenv foreman start

and point your browser at [http://127.0.0.1:3000](http://127.0.0.1:3000)

To get started, log in with Github. There is a simple admin interface
accessible at [http://127.0.0.1:3000/admin](http://127.0.0.1:3000/admin). To
access this, run the following to give your account admin rights:

    bundle exec rake app:promote_to_admin

### Installing Docker on OSX

If you're doing your development on Linux you're in luck because installing Docker is pretty straightforward. Just follow the instructions on the [Docker site](http://www.docker.io/gettingstarted/#h_installation).

If you're on OSX you could follow the [instructions on the Docker site](https://docs.docker.com/installation/mac/). Docker encourage OSX users to install their [Kitematic](https://kitematic.com/) application, a [GUI](https://en.wikipedia.org/wiki/Graphical_user_interface) for running Docker, that works with Morph. However there will be some extra configuration you will need to do to make it work with Morph.

We've made it easier by providing a Vagrantfile that sets up a VM, installs docker on it and makes sure that your development box can talk to docker on the VM.

First install [Vagrant](http://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads). Then,

    vagrant up dev

After the Vagrant vm is built, **run `vagrant halt dev` and then `vagrant up dev` again** to make sure the shared folders are correctly set up. Then you can continue with the [installation steps above](#to-install).

Just recently the Docker folks have released a version of the docker client that works on OS X. The first build is [available to download](http://test.docker.io/builds/Darwin/x86_64/docker-0.7.3.tgz). You might find this helpful later but isn't essential.

### Guard Livereload

We use Guard and Livereload so that whenever you edit a view in development the web page gets automatically reloaded. It's a massive time saver when you're doing design or lots of work in the view. To make it work run

    bundle exec guard

### Mail in development

By default in development mails are sent to [Mailcatcher](http://mailcatcher.me/). To install

    gem install mailcatcher

### Deploying to production

This section will not be relevant to most people. It will however be relevant if you're deploying to a production server.

#### git-encrypt

We're using [git-encrypt](https://github.com/shadowhand/git-encrypt) to encrypt certain files, like the private key for the SSL certificate. To make this work you have to do some [special things](https://github.com/shadowhand/git-encrypt#decrypting-clones) _before_ you clone the morph repository.

#### Production devops development

Install [Vagrant](http://www.vagrantup.com/) and [Ansible](http://www.ansible.com/). Comment out the user line in [`provisioning/playbook.yml`](https://github.com/openaustralia/morph/blob/17e05ed5bc540be683e5fdf90d1fefaa0f81c56f/provisioning/playbook.yml#L10-L11) and run `vagrant up local`. This will build and provision a box that looks and acts like production at `dev.morph.io`.

Add these lines to your `/etc/hosts` file:

    127.0.0.1  dev.morph.io
    127.0.0.1  faye.dev.morph.io

Once the box is created and provisioned, deploy the application to your Vagrant box:

    cap local deploy

To access the application you need to forward HTTP and HTTPS privileged ports.

**OS X**: There's a script to do this via the firewall `./local_port_forward_os_x.sh`.

**Linux**: On Linux the quickest way is to install the `redir` utility (`sudo aptitude install redir`) and then run these commands in separate terminals:

    sudo redir --lport 80 --cport 8000
    sudo redir --lport 443 --cport 8001

Now visit https://dev.morph.io/

#### Production provisioning and deployment

To deploy Morph to production, normally you'll just want to deploy using Capistrano:

    cap production deploy

When you've changed the Ansible playbooks to modify the infrastructure you'll want to run:

    ansible-playbook --user=root --inventory-file=provisioning/hosts provisioning/playbook.yml

### Running tests

If you're running guard (see above) the tests will also automatically run when you change a file.

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

Copyright OpenAustralia Foundation Limited 2013 - 2014. Licensed under the Affero GPL. See LICENSE file for more details.

### Authors

Matthew Landauer
