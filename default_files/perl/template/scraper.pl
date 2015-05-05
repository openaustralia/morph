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
