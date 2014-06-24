Buildpacks are a new feature that allows you to pick and choose which libraries you would like
your scraper to use. You are no longer limited to the libraries that are preinstalled on Morph.

The Buildpacks are borrowed from the Buildpacks used by Heroku. In principle anything that can
run on Heroku with Buildpacks should run on Morph too. This gives you enormous flexibility with
only small changes required to your scraper.

The basic idea, which is the same for every language, is that you add a new file (or two) to your
scraper repository which specifies which libraries you want installed. The details of how this works
is specific to each language. For the details of your language see below

## Ruby

### Installing gems
To install specific gems add a `Gemfile` to your repository. For instance to install the `mechanize` and `sqlite3` gem.

```
source 'https://rubygems.org'

gem "mechanize"
gem "sqlite3"
```

Then run `bundle update` which will work out which specific versions of each gem will be installed and it writes the result of that to `Gemfile.lock`

Make sure that you add *both* `Gemfile` and `Gemfile.lock` to your repository.

### Selecting Ruby version

You can also use the `Gemfile` to control which version of Ruby is run. For instance to ensure that your scraper is run with Ruby 1.9.3 add this to your `Gemfile`

```
ruby '1.9.3'
```

For the full list of support ruby versions see [the Heroku documentation for its Ruby support](https://devcenter.heroku.com/articles/ruby-support#ruby-versions).

### No Gemfile

When there is no `Gemfile` and `Gemfile.lock` in the scraper repository, a default version of those files is installed which is as close as possible to the ScraperWiki environment as it was in January 2014. This is done to make migration from ScraperWiki as easy as possible.

### References
* [Heroku Ruby Support](https://devcenter.heroku.com/articles/ruby-support)
* [Bundler](http://bundler.io/)

## PHP

### References
* [Heroku PHP Support](https://devcenter.heroku.com/articles/php-support)

## Perl

### References
* [Third-party Heroku Perl Buildpack](https://github.com/miyagawa/heroku-buildpack-perl)

## Python

### References
* [Heroku Python Support](https://devcenter.heroku.com/articles/python-support)
