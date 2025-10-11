# This is a template for a Perl scraper on morph.io (https://morph.io)
# including some code snippets below that you should find helpful

use LWP::UserAgent;
use HTML::TreeBuilder;
use Database::DumpTruck;

use strict;
use warnings;

# Turn off output buffering
$| = 1;

# Read in a page
my $ua = LWP::UserAgent->new;
my $response = $ua->get('https://example.com');
die "Failed to fetch: " . $response->status_line unless $response->is_success;
my $content = $response->decoded_content;

# Parse the web page
my $tb = HTML::TreeBuilder->new_from_content($content);

# Find something on the page using css selectors
my @h1s = $tb->look_down(_tag => 'h1');

# Open a database handle
my $dt = Database::DumpTruck->new({dbname => 'data.sqlite', table => 'data'});

# Write out to the sqlite database
foreach my $h1 (@h1s) {
    my $value = $h1->as_text();
    $value =~ s/^\s+|\s+$//g; # trim whitespace
    $dt->insert([{name => $value}]);
}

# An arbitrary query against the database
if (@h1s) {
    my $rows = $dt->execute("SELECT rowid AS id, name FROM data ORDER BY rowid desc LIMIT 3");
    foreach my $row (@$rows) {
        print "$row->{id}: $row->{name}\n";
    }
}

# You don't have to do things with the HTML::TreeBuilder and Database::DumpTruck libraries.
# You can use whatever libraries you want: https://morph.io/documentation/perl
# All that matters is that your final data is written to an SQLite database
# called "data.sqlite" in the current working directory which has at least a table
# called "data".
