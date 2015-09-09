<!-- TODO: Add gifs to illustrate steps where that would be helpful -->

This tutorial will take you through the process of writing a simple scraper
to collect data from the web.
This tutorial uses the Ruby programming language, but
you can apply the steps and techniques to any language available on morph.io.

In this tutorial you will:

* create a scraper on morph.io
* clone it using git to work with on your local machine
* make sure you have the necessary dependencies installed
* access information on a webpage using Mechanize
* write your scraping code
* publishing and running your scraper on morph.io

You’ll use morph.io, the command line and a code editor on your local machine.

## Find the data you’re looking for and workout if you can scrape it

In this tutorial you're going to write a simple scraper to collect
information about the elected members of Australia’s Federal Parliament.
For each member let’s capture their
*title*, *electorate*, *party*,
and the *url for their individual page on the Parliament’s website*.

The data you want to scrape needs to be available on the web.
We’ve copied a basic list of members from
[the Parliament’s website](http://www.aph.gov.au/Senators_and_Members/Parliamentarian_Search_Results?q=&mem=1&sen=1&par=-1&gen=0&ps=12)
to [`https://morph.io/documentation/examples/australian_members_of_parliament`](https://morph.io/documentation/examples/australian_members_of_parliament)
for practice scraping.
You will target this page to get the member information with your scraper.

Some webpages are much harder to scrape than others.
This member information is published in a simple html list,
rather than embedded in an image.
This means you should be able to write a scraper to collect it.
If the information was in an image or PDF
then it would be much harder to access programmatically and
therefor much harder to write a scraper for.

Now that you've found the data you want to scrape
and you know you *can* scrape it,
the next step is to set up your scraper.

## Create your scraper on morph.io and clone it locally

The easiest way to get started is
to [create a new scraper on morph.io](https://morph.io/scrapers/new).

Select the language you want to write your scraper in.
This tutorial uses Ruby, so let's go with that.

If you are a member of organisations on GitHub,
you can set the owner of your scraper to be
either your own account or one of your organisations.

Choose a name and description for your scraper.
Use keywords that will help you and others find this scraper on morph.io in the future.
Let's call this scraper “tutorial_members_of_australian_parliament”
and describe it as “Collects members of Australia’s Federal Parliament (tutorial)”.

Click “Create Scraper”!

After morph.io has finished creating the new scraper
you are taken to your fresh scraper page.
You want to clone all the template scraper code morph.io provides
to your local machine so you can work with it there.

On the scraper page there is a heading “Scraper code”,
with a button to copy the “git clone URL”.
This is the link to the GitHub repository of your scraper’s code.
Click the button to copy the url to your clipboard.

Open terminal on your local computer
and `cd` to the directory you want to work in.
Type `git clone ` then paste in the url you copied
to get something like:

```
git clone https://github.com/username/tutorial_members_of_australian_parliament.git`
```

This command pulls down the code from GitHub
and adds it to a new directory called `nsw_parliament_current_session_bills`.
Change to that directory with `cd nsw_parliament_current_sessions_bills`
and then list the files with `ls -al`. You should see a bunch of files including:

* **scraper.rb**, the file that morph.io runs and that you’ll write your scraping code in
* **Gemfile**, which defines the dependencies you’ll need to run your scraper.

Now that you have the template scraper on your local machine,
you need to make sure you have the necessary libraries installed to run it.

## Install the required local dependencies

If the Gemfile, you'll see a Ruby version and two libraries specified:

```
ruby "2.0.0"

gem "scraperwiki", git: "https://github.com/openaustralia/scraperwiki-ruby.git", branch: "morph_defaults"
gem "mechanize"
```

This is template code that helps you get started
by defining some basic dependencies for your scraper.
You can read more about [language versions](https://morph.io/documentation/language_version)
and [libraries](https://morph.io/documentation/libraries) in the morph.io documentation.

You can use [Bundler](http://bundler.io/) to manage a Ruby project’s dependencies.
Run, `bundle install` in terminal to check the Gemfile
and install any libraries (called gems in Ruby) required.
If you need to install Ruby or switch versions,
you can use a tool like [rbenv](https://robots.thoughtbot.com/using-rbenv-to-manage-rubies-and-gems)
or [rvm](https://github.com/rvm/rvm).

So far you’ve set up all your files,
cloned them to your machine,
and installed the necessary dependencies.
Now it’s time to write your scraper.

<!-- TODO: Break the scraping section up with heading to aid quick scanning,
           So someone can come along and quick find answers to something that’s
           blocking them.
-->
## Writing your scraper

It can be really helpful to start out writing your scraper in an interactive shell.
In the shell you’ll get quick feedback as you explore the page you’re trying to scrape,
instead of having to run your scraper file to see what your code does.

The interactive shell for ruby
is called [irb](https://en.wikipedia.org/wiki/Interactive_Ruby_Shell).
Start an irb session in your terminal with:

```
bundle exec irb
```

The `bundle exec` command executes your `irb` command
in the context of your project’s Gemfile.
This means that your specified gems will be available.

The first command you need to run in `irb` is:

```
require 'mechanize'
```

This loads in the Mechanize library.
Mechanize is a helpful library for making requesting and interacting with webpages.

Now you can create an instance of Mechanize
that will be your agent to do things like 'get' pages and 'click' on links:

```
agent = Mechanize.new
```

You want to get information for all the members you can.
Looking at [your target page](https://morph.io/documentation/examples/australian_members_of_parliament)
it turns out the members are spread across several pages.
You’ll have to scrape all 3 pages to get all the members.
Rather than worry about this now, lets start small.
Start by just collecting the information you want
for the first member on the first page.
Reducing the complexity as you start to write your code
will make it easier to debug as you go along.

In your irb session, use [the Mechanize `get` method](http://mechanize.rubyforge.org/Mechanize.html#method-i-get)
to get the first page with members listed on it.

```
url = "https://morph.io/documentation/examples/australian_members_of_parliament"
page = agent.get(url)
```

This returns the source of your page
as a [Mechanize Page object](http://mechanize.rubyforge.org/Mechanize/Page.html).
You’ll be pulling the information you want out of this object
using the handy Nokogiri XML searching methods that Mechanize loads in for you.
Let’s review some of these methods.

### at()

The [`at()`](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Searchable#at-instance_method)
method returns the first element that matches the selectors provided.
For example, `page.at(‘ul’)` returns the first `<ul>` element in the page
as a Nokogiri XML Element that you can parse.
There are a number of ways to target elements using the `at()` method.
We’re using a css style selector in this example
because many people are familiar with this style from writing CSS or jQuery.
You can also target elements by `class`, e.g. `page.at('.search-filter-results')`;
or `id`, e.g. `page.at('#content')`.

### search()

The [`search()`](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Searchable#search-instance_method)
method works like the `at()` method,
but returns an Array of every element that matches the target instead of just the first.
Running `page.search('li')` returns an Array of every `<li>` element in `page`.

You can chain these methods together to find specific elements.
`page.at('.search-filter-results').at('li').search('p')`
will return an Array of all `<p>` elements
found within the first `<li>` element
found within the first element with the class `.search-filter-results` on the page.

You can use the `at()` and `search()` methods
to get the first member list item on the page:

```
page.at('.search-filter-results').at('li')
```

This returns a big blob of code that can be hard to read.
You can use the `inner_text()` method
to help work out if got the element you’re looking for:
the first member in the list.

```
>> page.at('.search-filter-results').at('li').inner_text
=> "\n\nThe Hon Ian Macfarlane MP\n\n\n\n\n\nMember for\nGroom,Queensland\nParty\nLiberal Party of Australia\nConnect\n\nEmail\n\n\n"
```

Victory!

Now that you’ve found your first member,
you want to collect their
*title*, *electorate*, *party*, and the *url for their individual page*.
Let’s start with the title.

If you [view the page source in your browser](view-source:https://morph.io/documentation/examples/australian_members_of_parliament)
and look at the first member list item, you can see that
the title of the member, “The Hon Ian Macfarlane MP”,
is the text inside the link in the `<p>` with the class ‘title’.

```
<li>
  <p class='title'>
    <a href="http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=WN6">
      The Hon Ian Macfarlane MP
    </a>
  </p>
  <p class='thumbnail'>
    <a href="http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=WN6">
      <img alt="Photo of The Hon Ian Macfarlane MP" src="http://parlinfo.aph.gov.au/parlInfo/download/handbook/allmps/WN6/upload_ref_binary/WN6.JPG" width="80" />
    </a>
  </p>
  <dl>
    <dt>Member for</dt>
    <dd>Groom, Queensland</dd>
    <dt>Party</dt>
    <dd>Liberal Party of Australia</dd>
    <dt>Connect</dt>
    <dd>
      <a class="social mail" href="mailto:Ian.Macfarlane.MP@aph.gov.au"
      target="_blank">Email</a>
    </dd>
  </dl>
</li>
```

You can use the `.inner_text` method here.

```
>> page.at('.search-filter-results').at('li').at('.title').inner_text
=> "\nThe Hon Ian Macfarlane MP\n"
```

There it is: the title of the first member.
It’s got messy [`\n` whitespace characters](https://en.wikipedia.org/wiki/Newline#Representations)
around it though.
Never fear, you can clean it up with
the [Ruby method `strip`](http://ruby-doc.org/core-2.0.0/String.html#method-i-strip).

```
>> page.at('.search-filter-results').at('li').at('.title').inner_text.strip
=> "The Hon Ian Macfarlane MP"
```

You’ve successfully scraped the first bit of information you want.

Now that you’ve got some code for your scraper,
add it to your `scraper.rb` file and make your first commit.

You’ll want to come back to your `irb` session,
so leave it running and open your `scraper.rb` file in your code editor.
Replace the commented out template code
with the working code from your `irb` session.

Your `scraper.rb` should look like this:

```
require 'mechanize'

agent = Mechanize.new
url = 'https://morph.io/documentation/examples/australian_members_of_parliament'
page = agent.get(url)

page.at('.search-filter-results').at('li').at('.title').inner_text.strip
```

You actually want to collect members with this scraper,
so create a member object
and assign the text you’ve collected as it’s title:

```
require 'mechanize'

agent = Mechanize.new
url = 'https://morph.io/documentation/examples/australian_members_of_parliament'
page = agent.get(url)

member = {
  title: page.at('.search-filter-results').at('li').at('.title').inner_text.strip
}
```

Add a final line to the file to help
confirm that everything is working as expected.

```
p member
```

You can now, back in on the command line
in the folder for your project,
run this file in Ruby:

```
bundle exec ruby scraper.rb
```

The scraper runs and the `p` command returns your `member`:

```
> bundle exec ruby scraper.rb
{:title=>"The Hon Ian Macfarlane MP"}
```

This is a good time to make your first git commit for this project.

Now that you’ve got the title for the first member
get the *electorate* (the place the member is ‘member for’) and *party*.

Looking at the page source again,
you can see this information is in the first and second `<dd>` elements
in the member’s `<li>`.


```
<li>
  <p class='title'>
    <a href="http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=WN6">
      The Hon Ian Macfarlane MP
    </a>
  </p>
  <p class='thumbnail'>
    <a href="http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=WN6">
      <img alt="Photo of The Hon Ian Macfarlane MP" src="http://parlinfo.aph.gov.au/parlInfo/download/handbook/allmps/WN6/upload_ref_binary/WN6.JPG" width="80" />
    </a>
  </p>
  <dl>
    <dt>Member for</dt>
    <dd>Groom, Queensland</dd>
    <dt>Party</dt>
    <dd>Liberal Party of Australia</dd>
    <dt>Connect</dt>
    <dd>
      <a class="social mail" href="mailto:Ian.Macfarlane.MP@aph.gov.au"
      target="_blank">Email</a>
    </dd>
  </dl>
</li>
```

Get the *electorate* and *party*
by first getting an array of the `<dd>` elements
and then selecting the one you want
by [its index in the array](http://ruby-doc.org/core-2.0.0/Array.html#method-i-5B-5D).
Remember that `[0]` is the first item in an Array.

Try getting the data in your `irb` session:

```
>> page.at('.search-filter-results').at('li').search('dd')[0].inner_text
=> "Groom, Queensland"
>> page.at('.search-filter-results').at('li').search('dd')[1].inner_text
=> "Liberal Party of Australia"
```

Then add the code to expand your `member` object in your `scraper.rb`:

```
member = {
  title: page.at('.search-filter-results').at('li').at('.title').inner_text.strip,
  electorate: page.at('.search-filter-results').at('li').search('dd')[0].inner_text,
  party: page.at('.search-filter-results').at('li').search('dd')[1].inner_text
}
```

Save and run your scraper using `bundle exec ruby scraper.rb`
and check that you’re object includes the attributes with values you expect.

Ok, now you just need the *url for the member’s individual page*.
Look at that source code again and you’ll find it
in the `href` of the `<a>` inside the `<p>` with the class `title`.

In your `irb` session, first get the `<a>` element:

```
>> page.at('.search-filter-results').at('li').at('.title a')
=> #<Nokogiri::XML::Element:0x3fca485cfba0 name="a" attributes=[#<Nokogiri::XML::Attr:0x3fca48432a18 name="href" value="http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=WN6">] children=[#<Nokogiri::XML::Text:0x3fca4843b5c8 "The Hon Ian Macfarlane MP">]>
```

You get a Nokogiri XML Element with one attribute.
The attribute has the name “href” and the value is the url you want.
You can use the
[`attr() method`](http://www.rubydoc.info/github/sparklemotion/nokogiri/Nokogiri/XML/Reader#attribute-instance_method)
here to return this value:

```
>> page.at('.search-filter-results').at('li').at('.title a').attr('href')
=> "http://www.aph.gov.au/Senators_and_Members/Parliamentarian?MPID=WN6"
```

You can now add this final attribute to your member object in `scraper.rb`:

```
member = {
  title: page.at('.search-filter-results').at('li').at('.title').inner_text.strip,
  electorate: page.at('.search-filter-results').at('li').search('dd')[0].inner_text,
  party: page.at('.search-filter-results').at('li').search('dd')[1].inner_text,
  url: page.at('.search-filter-results').at('li').at('.title a').attr('href')
}
```

Save and run your scraper file to make sure all is well.
This is a good time to do another `git commit` to save your progress.

Now you’ve written a scraper to get
information about one member of Australian Parliament.
It’s time to get information about all the members on the first page.

Currently your using `page.at('.search-filter-results').at('li')`
to target the first list item in the members list.
You can adapt this to get every list item using the `search()` method:

```
page.at('.search-filter-results').search('li')
```

Use a ruby [`each` loop](http://ruby-doc.org/core-2.0.0/Array.html#method-i-each)
to run your code to collect and print your member object
once for each list item.

```
page.at('.search-filter-results').search('li').each do |li|
  member = {
    title: li.at('.title').inner_text.strip,
    electorate: li.search('dd')[0].inner_text,
    party: li.search('dd')[1].inner_text,
    url: li.at('.title a').attr('href')
  }

  p member
end
```

Save and run the file and see if
it collects all the members on the page as expected.
Now you’re really scraping!

You still don’t have all the members though,
they are split over 3 pages and you only have the first.

## Dealing with pagination

[Visit the target page](https://morph.io/documentation/examples/australian_members_of_parliament)
in your browser and navigate between the different pages
using the links above the members list.
Notice that when you go to [page 2](https://morph.io/documentation/examples/australian_members_of_parliament?page=2)
the url is mostly the same
except it has the [query string](https://en.wikipedia.org/wiki/Query_string)
`?page=2` on the end:

```
https://morph.io/documentation/examples/australian_members_of_parliament?page=2
```

When scraping websites pay close attention
to the page URLs and their query strings.
They often include clues to help you scrape.

It turns out you can navigate between the different member pages
by just changing the page number to [1](https://morph.io/documentation/examples/australian_members_of_parliament?page=1),
[2](https://morph.io/documentation/examples/australian_members_of_parliament?page=2) or
[3](https://morph.io/documentation/examples/australian_members_of_parliament?page=3)
in the query string.

You can use what you've discovered as the basis for another `each` loop.
This time you want to make a loop that runs your scraping code for each page.

You know that the three pages with members are pages 1, 2 and 3.
Create an Array of these page numbers `["1", "2", "3"]`
and then loop through these numbers
to run your `get` request and scraping code for each page.

```
require 'mechanize'

agent = Mechanize.new
url = 'https://morph.io/documentation/examples/australian_members_of_parliament'

["1", "2", "3"].each do |page_number|
  page = agent.get(url + "?page=" + page_number)

  page.at('.search-filter-results').search('li').each do |li|
    member = {
      title: li.at('.title').inner_text.strip,
      electorate: li.search('dd')[0].inner_text,
      party: li.search('dd')[1].inner_text,
      url: li.at('.title a').attr('href')
    }

    p member
  end
end
```

Save and run your `scraper.rb`.
You should now see all 150 members details printed.
Well done!
You should do a `git commit` for this working code.

This is great—but there’s one more step.
You’ve written a scraper that collects the details of members of Parliament
and prints them to the command line—
but you actually want to save this data.
You need to store the information you’ve scraped
so you can actually use it in your projects.

## Saving the data you scrape

Scrapers on [morph.io](https://morph.io/)
use the handy [ScraperWiki library](https://github.com/openaustralia/scraperwiki-ruby/tree/morph_defaults)
to save data to an [SQLite database](https://en.wikipedia.org/wiki/SQLite).
This is how all data in morph.io is stored.
Each scraper page provides options to download
the SQLite database, a CSV file of each table,
or access the data via an [API](https://morph.io/documentation/api).

You might remember seeing the ScraperWiki library
listed as a dependency in your Gemfile earlier:

```
ruby "2.0.0"

gem "scraperwiki", git: "https://github.com/openaustralia/scraperwiki-ruby.git", branch: "morph_defaults"
gem "mechanize"
```

To use this library in your scraper,
you need to declare that it is required at the top of your `scraper.rb`
in the same way you have for the Mechanize library:

```
require 'mechanize'
require 'scraperwiki'
```

You can save data using the [`ScraperWiki.save_sqlite()` method](https://github.com/openaustralia/scraperwiki-ruby/blob/morph_defaults/README.md#scraperwikisave_sqliteunique_keys-data-table_name--dataverbose).
This method takes care of the messy buisness
of creating a database and handling duplication for you.
There are two auguments you need to pass it:
an array of the record’s unique keys
so it knows when to override or update a record,
and the data that you want to save.

A member’s title is unique to them
so you can use that as your unique key.
The data you want to save is your `member` object.
After your `p member` statement is a good place to save your data.

```
p member
ScraperWiki.save_sqlite([:title], member)
```

Your `scraper.rb` should now look like this:

```
require 'mechanize'
require 'scraperwiki'

agent = Mechanize.new
url = 'https://morph.io/documentation/examples/australian_members_of_parliament'

["1", "2", "3"].each do |page_number|
  page = agent.get(url + "?page=" + page_number)

  page.at('.search-filter-results').search('li').each do |li|
    member = {
      title: li.at('.title').inner_text.strip,
      electorate: li.search('dd')[0].inner_text,
      party: li.search('dd')[1].inner_text,
      url: li.at('.title a').attr('href')
    }

    p member
    ScraperWiki.save_sqlite([:title], member)
  end
end
```

Save and run your file.
The command line output should be unchanged—
but if you view the files in your project directory
you will see a new file `data.sqlite`.

Great job.
You’ve now written a scraper to collect data and save it to a database.
It’s time to put your new scraper code on morph.io
so you can show the world how cool you are—and
so it can take care of running the thing,
storing your data,
and providing you easy access to it.

## Running your scraper on morph.io

Morph.io runs scraper code that is stored in public GitHub repositories.
To run your scraper on morph.io,
you’ll first have to push it back up to GitHub repository
you originally cloned it from.

Start off with another `git commit` to save any outstanding changes.

Push your changes up to your remote GitHub repository with:

```
git push origin master:master
```

Now go view your scraper’s page on GitHub
(the url will be something like
github.com/*yourusername*/*the_name_of_this_scraper*).
Navigate to view your `scraper.rb` file on GitHub
and see that it’s got all your local changes.

You can now go over to your scraper’s page on morph.io
and click the “Run scraper” button near the top of the page.
The moment of truth is upon us.

As your scraper runs you will see all your console output
print the data for the members you are scraping.
A few seconds later, underneath the heading “Data”,
you’ll find a table showing a representative ten rows of data
and buttons to download your data in a range of formats.

Take a moment to explore the download options
and check that the data looks as you expected.

## That’s all folks

Well done my friend, you’ve just written a web scraper.

With just a few lines of code
you’ve collected information from a website
and saved it in a structured format you can play with.
You’ve published your work for all to see on morph.io
and set it to run, store and provide access to your data.

If you want to get really fancy
you can set your scraper to *auto run daily*
on your scraper’s settings page
so it’s stays up to date with any changes to the members list.

Before you go mad with power,
go and explore some of the scrapers on morph.io.
Try searching for
[topics you find interesting](https://morph.io/search?q=parliament)
and [domains you know](https://morph.io/search?utf8=%E2%9C%93&type=&show=&q=.gov).
Get ideas for what to scrape next
and learn from other peoples’ scraper code.

Remember to [post questions to the help forums](https://help.morph.io/)
if you get blocked by tricky problems.

If you have any feedback on this tutorial we’d love to hear it.
Please [log an issue](https://github.com/openaustralia/morph/issues/new)
to report a specific problem or make a suggestion.

Now go forth with your new powers and scrape all the things!
