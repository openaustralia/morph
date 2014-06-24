# A joyful birth of some documentation!

* [What languages can scrapers be written in?](#languages)
* [In what format do I write out the data I've scraped?](#format)
* [What version of the language and what libraries do I have access to?](#libraries)
* [What if I want to install a library that isn't currently installed?](#install)
* [How do I run a scraper on my own machine?](#run_locally)
* [What limits are there on numbers of scrapers, usage, etc.?](#limits)
* [Your responsibility](#responsibility)

<h3 id="languages" class="section">What languages can scrapers be written in?</h3>
Scrapers can be written in [Ruby](https://www.ruby-lang.org/en/), [PHP](http://www.php.net/), [Python](https://www.python.org/),
or [Perl](http://www.perl.org/). Simply follow the naming convention:

* Ruby - `scraper.rb`
* PHP - `scraper.php`
* Python - `scraper.py`
* Perl - `scraper.pl`

<h3 id="format" class="section">In what format do I write out the data I've scraped?</h3>
Write to a table `#{Morph::Database.sqlite_table_name}` in an sqlite database in the current
working directory called `#{Morph::Database.sqlite_db_filename}`. How you do that and what fields you include is entirely up to you.

<h3 id="libraries" class="section">What version of the language and what libraries do I have access to?</h3>
The language versions and libraries available are intended as close as possible to those available on
[ScraperWiki Classic](https://classic.scraperwiki.com/) as of January 2014. The main difference is that the scraperwiki library
has been patched to write out by default to the convention used in Morph for the table and sqlite database names.

#### Ruby 1.9.2-p320
Here is the [list of installed Gems](https://github.com/openaustralia/morph-docker-ruby/blob/master/Gemfile) directly from the
source that's used to build the docker image.

#### PHP 5.3.10
The version of PHP is very slightly more recent than the one on ScraperWiki classic. It is a bug fix release.
To see in detail what's installed see the [docker source on Github](https://github.com/openaustralia/morph-docker-php).

#### Python 2.7.3
This version of Python is very slightly more recent than the one on ScraperWiki Classic (2.7.1). It is a bug fix release.
To see in detail what libraries are installed see the [docker source on Github](https://github.com/openaustralia/morph-docker-python).

#### Perl 5.14.2
For list of packages that are installed see the [docker source on Github](https://github.com/openaustralia/morph-docker-perl).

<h3 id="install" class="section">What if I want to install a library that isn't currently installed?</h3>
Right now you have to either [ask us to do it for you](mailto:contact@oaf.org.au) or make a pull request against one of the
morph-docker repositories which build the docker images.

The plan ([#3](https://github.com/openaustralia/morph/issues/3) [#153](https://github.com/openaustralia/morph/issues/153)
[#154](https://github.com/openaustralia/morph/issues/154)) is to make this a lot easier using Buildpacks.
For instance in Ruby you'll be able to include your own Gemfile which will be automatically loaded for you.

<h3 id="run_locally" class="section">How do I run a scraper on my own machine?</h3>
Install [morph command line](https://github.com/openaustralia/morph-cli). First, check you have Ruby 1.9 or greater and rubygems installed. Then,

    gem install morph-cli

To run a scraper go to the directory and

    morph

It will run your local scraper on the Morph server and stream the console output back to you. You can use this with any support scraper
language without the hassle of having to install lots of things.

<h3 id="limits" class="section">What limits are there on numbers of scrapers, usage, etc.?</h3>
Right now there are none. We are trusting you that you won't abuse this. Note that we are keeping track of the amount of cpu time (and a whole
bunch of other metrics) that you and your scrapers are using. So, if we do find that you are using too much (and no we don't know what that
is right now) we reserve the right to kick you out. In reality first we'll ask you nicely to stop.

We're thinking about putting limits in place on free accounts as this service grows. Also, potentially adding support for private scrapers
under a paid plan as well. Let us know [what you think and want](mailto:contact@oaf.org.au).

<h3 id="responsibility" class="section">Your responsibility</h3>
Please keep things legal. Don't scrape anything you're not allowed to. If you do end up doing anything you're not allowed to, it's your
responsibility not ours.
