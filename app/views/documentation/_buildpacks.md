Buildpacks are a new feature that allows you to pick and choose which libraries you would like
your scraper to use. You are no longer limited to the libraries that are preinstalled on Morph.

The Buildpacks are borrowed from the Buildpacks used by Heroku. In principle anything that can
run on Heroku with Buildpacks should run on Morph too. This gives you enormous flexibility with
only small changes required to your scraper.

The basic idea, which is the same for every language, is that you add a new file (or two) to your
scraper repository which specifies which libraries you want installed. The details of how this works
is specific to each language. For the details of your language see below

## Ruby

References

* [Heroku Ruby Support](https://devcenter.heroku.com/articles/ruby-support)

## PHP

References

* [Heroku PHP Support](https://devcenter.heroku.com/articles/php-support)

## Perl

References

* [Third-party Heroku Perl Buildpack](https://github.com/miyagawa/heroku-buildpack-perl)

## Python

References

* [Heroku Python Support](https://devcenter.heroku.com/articles/python-support)
