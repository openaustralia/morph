### Installing gems
To install specific gems add a `Gemfile` to your repository. For instance to install the `mechanize` and `sqlite3` gem.

<pre>
source 'https://rubygems.org'

gem "mechanize"
gem "sqlite3"
</pre>

Then run `bundle update` which will work out which specific versions of each gem will be installed and it writes the result of that to `Gemfile.lock`

Make sure that you add *both* `Gemfile` and `Gemfile.lock` to your repository.

### Selecting Ruby version

You can also use the `Gemfile` to control which version of Ruby is run. For instance to ensure that your scraper is run with Ruby 1.9.3 add this to your `Gemfile`

<pre>
ruby '1.9.3'
</pre>

For the full list of support ruby versions see [the Heroku documentation for its Ruby support](https://devcenter.heroku.com/articles/ruby-support#ruby-versions).

### No Gemfile

When there is no `Gemfile` and `Gemfile.lock` in the scraper repository, a default version of those files is installed which is as close as possible to the ScraperWiki environment as it was in January 2014. This is done to make migration from ScraperWiki as easy as possible.

### References
* [Heroku Ruby Support](https://devcenter.heroku.com/articles/ruby-support)
* [Bundler](http://bundler.io/)
* [Morph Default Gemfile](https://github.com/openaustralia/morph/blob/master/default_files/ruby/Gemfile)
