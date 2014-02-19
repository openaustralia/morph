require 'spec_helper'

describe Morph::Language do
  describe ".human" do
    it { Morph::Language.human(:ruby).should == "Ruby" }
    it { Morph::Language.human(:python).should == "Python" }
    it { Morph::Language.human(:php).should == "PHP" }
  end

  describe ".default_scraper" do
    it do
      Morph::Language.default_scraper(:ruby).should == <<-EOF
# This is a template for a Ruby scraper on Morph (https://morph.io)
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

# You don't have to do things with the Mechanize or ScraperWiki libraries. You can use whatever gems are installed
# on Morph for Ruby (https://github.com/openaustralia/morph-docker-ruby/blob/master/Gemfile) and all that matters
# is that your final data is written to an Sqlite database called data.sqlite in the current working directory which
# has at least a table called data.
      EOF
    end

    it do
      Morph::Language.default_scraper(:php).should == <<-EOF
<?
// This is a template for a PHP scraper on Morph (https://morph.io)
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
 
// You don't have to do things with the ScraperWiki library. You can use whatever is installed
// on Morph for PHP (See https://github.com/openaustralia/morph-docker-php) and all that matters
// is that your final data is written to an Sqlite database called data.sqlite in the current working directory which
// has at least a table called data.
?>
      EOF
    end

    it do
      Morph::Language.default_scraper(:python).should == <<-EOF
# This is a template for a Python scraper on Morph (https://morph.io)
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

# You don't have to do things with the ScraperWiki and lxml libraries. You can use whatever libraries are installed
# on Morph for Python (https://github.com/openaustralia/morph-docker-python/blob/master/pip_requirements.txt) and all that matters
# is that your final data is written to an Sqlite database called data.sqlite in the current working directory which
# has at least a table called data.
      EOF
    end
  end
end
