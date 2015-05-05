require 'spec_helper'

describe Morph::Language do
  let(:ruby) { Morph::Language.new(:ruby) }
  let(:python) { Morph::Language.new(:python)}
  let(:php) { Morph::Language.new(:php) }
  let(:perl) { Morph::Language.new(:perl) }

  describe "#human" do
    it { ruby.human.should == "Ruby" }
    it { python.human.should == "Python" }
    it { php.human.should == "PHP" }
    it { perl.human.should == "Perl" }
  end

  describe "#scraper_templates" do
    it do
      ruby.scraper_templates(false).keys.should == ["scraper.rb"]
      ruby.scraper_templates(false)["scraper.rb"].should == <<-EOF
# This is a template for a Ruby scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# require 'scraperwiki'
# require 'mechanize'
#
# agent = Mechanize.new
#
# # Read in a page
# page = agent.get("http://foo.com")
#
# # Find somehing on the page using css selectors
# p page.at('div.content')
#
# # Write out to the sqlite database using scraperwiki library
# ScraperWiki.save_sqlite(["name"], {"name" => "susan", "occupation" => "software developer"})
#
# # An arbitrary query against the database
# ScraperWiki.select("* from data where 'name'='peter'")

# You don't have to do things with the Mechanize or ScraperWiki libraries.
# You can use whatever gems you want: https://morph.io/documentation/ruby
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
      EOF
    end

    it { ruby.scraper_templates(true).keys.sort.should == ["Gemfile", "Gemfile.lock", "scraper.rb"] }
    it { ruby.scraper_templates(false)["scraper.rb"].should == ruby.scraper_templates(true)["scraper.rb"] }

    it do
      php.scraper_templates(false).keys.should == ["scraper.php"]
      php.scraper_templates(false)["scraper.php"].should == <<-EOF
<?
// This is a template for a PHP scraper on morph.io (https://morph.io)
// including some code snippets below that you should find helpful

// require 'scraperwiki.php';
// require 'scraperwiki/simple_html_dom.php';
//
// // Read in a page
// $html = scraperwiki::scrape("http://foo.com");
//
// // Find something on the page using css selectors
// $dom = new simple_html_dom();
// $dom->load($html);
// print_r($dom->find("table.list"));
//
// // Write out to the sqlite database using scraperwiki library
// scraperwiki::save_sqlite(array('name'), array('name' => 'susan', 'occupation' => 'software developer'));
//
// // An arbitrary query against the database
// scraperwiki::select("* from data where 'name'='peter'")

// You don't have to do things with the ScraperWiki library.
// You can use whatever libraries you want: https://morph.io/documentation/php
// All that matters is that your final data is written to an SQLite database
// called "data.sqlite" in the current working directory which has at least a table
// called "data".
?>
      EOF
    end

    it do
      python.scraper_templates(false).keys.should == ["scraper.py"]
      python.scraper_templates(false)["scraper.py"].should == <<-EOF
# This is a template for a Python scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# import scraperwiki
# import lxml.html
#
# # Read in a page
# html = scraperwiki.scrape("http://foo.com")
#
# # Find something on the page using css selectors
# root = lxml.html.fromstring(html)
# root.cssselect("div[align='left']")
#
# # Write out to the sqlite database using scraperwiki library
# scraperwiki.sqlite.save(unique_keys=['name'], data={"name": "susan", "occupation": "software developer"})
#
# # An arbitrary query against the database
# scraperwiki.sql.select("* from data where 'name'='peter'")

# You don't have to do things with the ScraperWiki and lxml libraries.
# You can use whatever libraries you want: https://morph.io/documentation/python
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
      EOF
    end

    it do
      perl.scraper_templates(false).keys.should == ["scraper.pl"]
      perl.scraper_templates(false)["scraper.pl"].should == <<-EOF
# This is a template for a Perl scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

# use LWP::Simple;
# use HTML::TreeBuilder;
# use Database::DumpTruck;

# use strict;
# use warnings;

# # Turn off output buffering
# $| = 1;

# # Read out and parse a web page
# my $tb = HTML::TreeBuilder->new_from_content(get('http://example.com/'));

# # Look for <tr>s of <table id="hello">
# my @rows = $tb->look_down(
#     _tag => 'tr',
#     sub { shift->parent->attr('id') eq 'hello' }
# );

# # Open a database handle
# my $dt = Database::DumpTruck->new({dbname => 'data.sqlite', table => 'data'});
#
# # Insert some records into the database
# $dt->insert([{
#     Name => 'Susan',
#     Occupation => 'Software Developer'
# }]);

# You don't have to do things with the HTML::TreeBuilder and Database::DumpTruck libraries.
# You can use whatever libraries you want: https://morph.io/documentation/perl
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
      EOF
    end
  end
end
