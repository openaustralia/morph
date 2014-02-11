[![Stories in Ready](https://badge.waffle.io/openaustralia/morph.png?label=ready)](https://waffle.io/openaustralia/morph) [![Build Status](https://travis-ci.org/openaustralia/morph.png?branch=master)](https://travis-ci.org/openaustralia/morph) [![Code Climate](https://codeclimate.com/github/openaustralia/morph.png)](https://codeclimate.com/github/openaustralia/morph)

## Morph: A scraping platform

* A [Heroku](https://www.heroku.com/) for [Scrapers](https://en.wikipedia.org/wiki/Web_scraping)
* All code and collaboration through [GitHub](https://github.com/)
* Write your scrapers in Ruby, Python or PHP
* Simple API to grab data
* Schedule scrapers or run manually
* Process isolation via [Docker](http://www.docker.io/)
* Trivial to move scraper code and data from [ScraperWiki Classic](https://classic.scraperwiki.com/)
* Email alerts for broken scrapers

### Dependencies
Ruby 2.0.0, Docker, MySQL, SQLite 3
(On OS X for development also Vagrant & VirtualBox to host a VM with Docker - see below for more)

### To Install

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

Edit `.env` with the details of the application you've just created

Now you'll need to build the Docker container that scrapers run in.

    dotenv bundle exec rake app:update_docker_image

Now you can start the server

    bundle exec rake db:setup
    bundle exec foreman start

and point your browser at [http://127.0.0.1:3000](http://127.0.0.1:3000)

### Installing Docker on OSX

If you're doing your development on Linux you're in luck because installing Docker is pretty straightforward. Just follow the instructions on the [Docker site](http://www.docker.io/gettingstarted/#h_installation).

If you're on OSX you could follow the instructions on the [Docker site](http://www.docker.io/gettingstarted/#h_installation) as well. However there will be some extra configuration you will need to do to make it work with Morph. 

We've made it easier by providing a Vagrantfile that sets up a VM, installs docker on it and makes sure that your development box can talk to docker on the VM.

First install [Vagrant](http://www.vagrantup.com/downloads.html) and [VirtualBox](https://www.virtualbox.org/wiki/Downloads). Then,

    vagrant up dev

Just recently the Docker folks have released a version of the docker client that works on OS X. The first build is [available to download](http://test.docker.io/builds/Darwin/x86_64/docker-0.7.3.tgz). You might find this helpful later but isn't essential.

### Guard Livereload

We use Guard and Livereload so that whenever you edit a view in development the web page gets automatically reloaded. It's a massive time saver when you're doing design or lots of work in the view. To make it work run

    bundle exec guard

### Mail in development

By default in development mails are sent to [Mailcatcher](http://mailcatcher.me/). To install

    gem install mailcatcher

### Special notes if you're deploying to production

This section will not be relevant to most people. It will however be relevant if you're deploying to a production server.

We're using [git-encrypt](https://github.com/shadowhand/git-encrypt) to encrypt certain files, like the private key for the SSL certificate. To make this work you have to do some [special things](https://github.com/shadowhand/git-encrypt#decrypting-clones) _before_ you clone the morph repository. 

### Running tests

If you're running guard (see above) the tests will also automatically run when you change a file. By default it's setup to use [Zeus](https://github.com/burke/zeus) which speeds things up considerably. You'll need to install this with

    gem install zeus

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

### Copyright & License

Copyright OpenAustralia Foundation Limited 2013 - 2014. Licensed under the Affero GPL. See LICENSE file for more details.

### Authors

Matthew Landauer

