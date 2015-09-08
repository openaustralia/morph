<!-- TODO: Add gifs to illustrate steps where that would be helpful -->

This tutorial will take you through the process of writing a simple scraper to collect data from the web. This tutorial uses the Ruby programming language, but you can apply the steps and techniques to any language available on morph.io.

In this tutorial we will:

* find the information you want to scrape on the web
* create a scraper on morph.io
* clone it using git to work with on your local machine
* make sure you have the necessary dependencies installed
* access information on a webpage using Mechanize
* write your scraping code
* publishing and running your scraper on morph.io

## Find the data you’re looking for and workout if you can scrape it

In this tutorial we're going to write a simple scraper to collect information about every bill introduced into New South Wales Parliament. For each bill let’s capture the *name of the bill*, the *house of origin*, and the *url of the bill’s main page*.

Start by doing a quick search for the information you want in your search engine of choice. The first link I found [searching “bills introduced into NSW parliament Australia” in Duck Duck Go](https://duckduckgo.com/?q=bills+introduced+into+NSW+parliament+Australia), is [Bills Overview - NSW Parliament](http://www.parliament.nsw.gov.au/prod/parlment/nswbills.nsf/V3BillsHome). That page has a link to [_All bills since 1997_](http://www.parliament.nsw.gov.au/prod/parlment/nswbills.nsf/V3BillsListAll).

The data you want to scrape needs to be available on the web. It seems that only bills since 1997 are available, so we'll have to settle for that for now. It would be helpful if Parliament published the bills as a nice spreadsheet or API that I can use in my projects, but they don't. We’ll have to write a scraper to collect all the bills!

Is it possible to scrape this information? The bills information is published in a simple html table, rather than imbedded in an image. This means we should be able to write a scraper to collect it. If the information was in an image or PDF then it would be much harder to access programatically.

Now that we've found our data and we know we can scrape it, the next step is to set up out scraper.

## Create your scraper on morph.io and clone it locally

The easiest way to get started is to [create a new scraper on morph.io](https://morph.io/scrapers/new).

Select the language we want to write our scraper in. This tutorial uses Ruby, so let's go with that.

If you are a member of organisations on GitHub, you can set the owner of your scraper to be either your own account or one of your organisations.

Choose a name and description for your scraper. Use keywords that will help you and others find this scraper on morph.io in the future. Let's call this scraper “bills_in_nsw_parliament” and describe it as “Bills introduced into New South Wales (NSW) Parliament, Australia”.

Click “Create Scraper”!

After morph.io has finished creating the new scraper we are taken to our fresh scraper page. We want to clone all the template scraper code morph.io provides to our local machine so we can work with it there. Running 

On the scraper page there is a heading “Scraper code”, with a button to copy the “git clone URL”. This is the link to the GitHub repository of your scraper’s code. Click the button to copy the url to your clipboard.

Open terminal on your local computer and `cd` to the directory you want to clone your fines to, in my case `cd git`. Type `git clone ` then paste in the url you copied to get something like `git clone https://github.com/equivalentideas/nsw_parliament_current_session_bills.git`, and run the command.

This pulls down the code from GitHub and adds it to a new directory in the `git`, in this case `~/git/nsw_parliament_current_session_bills`. Change to that directory with `cd nsw_parliament_current_sessions_bills` and then list the files with `ls -al`. You should see a bunch of files including:

* **scraper.rb**, the file that morph.io runs and that you’ll write our scraping code in
* **Gemfile**, which defines the dependencies you’ll need to run your scraper.

Now that we have all our template scraper on our local machine, we need to make sure we have the necessary libraries installed to run it.

## Install the required local dependencies

If the Gemfile, you'll see a Ruby version and two libraries specified:

```
ruby "2.0.0"

gem "scraperwiki", git: "https://github.com/openaustralia/scraperwiki-ruby.git", branch: "morph_defaults"
gem "mechanize"
```

This is template code that helps you get started by defining some basic dependencies for your scraper. You can read more about [language versions](https://morph.io/documentation/language_version) and [libraries](https://morph.io/documentation/libraries) in the morph.io documentation.

You can use [Bundler](http://bundler.io/) to manage a Ruby project’s dependencies. Run, `bundle install` in terminal to check the Gemfile and install any libraries (called gems in Ruby) required. If you need to install or switch Ruby versions, you can use a tool like [rbenv](https://robots.thoughtbot.com/using-rbenv-to-manage-rubies-and-gems) or [rvm](https://github.com/rvm/rvm).

So far we’ve set up all our files, cloned them to our machine, and installed the necessary dependencies. Now it’s time to write our scraper.
