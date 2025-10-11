<?php
// This is a template for a PHP scraper on morph.io (https://morph.io)
// including some code snippets below that you should find helpful

require_once 'vendor/autoload.php';
require_once 'vendor/openaustralia/scraperwiki/scraperwiki.php';

use PGuardiario\PGBrowser;
use Torann\DomParser\HtmlDom;

// Read in a page
$browser = new PGBrowser();
$page = $browser->get("https://example.com");

// Find something on the page using css selectors
$dom = HtmlDom::fromString($page->html);

foreach($dom->find("h1") as $h1) {
    $value = trim($h1->plaintext);
    // Write out to the sqlite database using scraperwiki library
    scraperwiki::save(['name'], ['name' => $value]);
}

// An arbitrary query against the database
$rows = scraperwiki::select("rowid AS id, name FROM data");
foreach($rows as $row) {
    echo $row['id'] . ": " . $row['name'] . "\n";
}

// You don't have to do things with the ScraperWiki library.
// You can use whatever libraries you want: https://morph.io/documentation/php
// All that matters is that your final data is written to an SQLite database
// called "data.sqlite" in the current working directory which has at least a table
// called "data".
?>
