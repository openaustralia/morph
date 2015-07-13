### Quickstart

1. Install `bundler`: a Ruby package manager you’ll use to install the `scraperwiki` gem.<br>
Also install the `sqlite` development headers because `scraperwiki` will need them.
<pre>$ sudo apt-get install bundler libsqlite3-dev</pre>

2. Fork the repo you want to work on, or [start a new one](https://morph.io/scrapers/new).
3. Clone it:
<pre>
mkdir oaf
cd oaf
git clone git@github.com:yourname/example.git
cd example
</pre>

3. If there’s no Gemfile, use this simple one:
<pre>
source 'https://rubygems.org'
gem 'scraperwiki', git: 'https://github.com/openaustralia/scraperwiki-ruby.git', branch: 'morph_defaults'
gem 'mechanize'
</pre>

4. Use bundler to install these Ruby gems locally:
<pre>bundle install --path ../vendor/bundle</pre>
This will create a file called `Gemfile.lock`.<br>
Make sure that you add *both* `Gemfile` and `Gemfile.lock` to your repository.

5. Run the scraper. Use bundler to initialize the environment:
<pre>bundle exec ruby scraper.rb</pre>

### Installing gems

To have `morph.io` install specific gems for your scraper, add a `Gemfile` to your repository. For instance to install the `mechanize` and `sqlite3` gems:

<pre>
source 'https://rubygems.org'
gem "mechanize"
gem "sqlite3"
</pre>

Then run `bundle update`. This will work out which specific versions of each gem will be installed and write the result of that to `Gemfile.lock`.

Make sure that you add *both* `Gemfile` and `Gemfile.lock` to your repository.

### Selecting the Ruby version

You can also use the `Gemfile` to control which version of Ruby is run. For instance: to ensure that your scraper is run with Ruby 1.9.3, add this to your `Gemfile`:

<pre>
ruby '1.9.3'
</pre>

For the full list of support ruby versions see [the Heroku documentation for its Ruby support](https://devcenter.heroku.com/articles/ruby-support#ruby-versions).
