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
