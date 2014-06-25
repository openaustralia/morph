# This is a template for a Perl scraper on Morph (https://morph.io)
# including some code snippets below that you should find helpful

# use LWP::Simple;
# use HTML::TreeBuilder;
# use Database::DumpTruck;

# use strict;
# use warnings;

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
# # Insert content of <td id="name"> and <td id="age"> into the database
# $dt->insert([map {{
#     Name => $_->look_down(_tag => 'td', id => 'name')->content,
#     Age => $_->look_down(_tag => 'td', id => 'age')->content,
# }} @rows]);

# You don't have to do things with the HTML::TreeBuilder and Database::DumpTruck
# libraries. You can use whatever libraries are installed on Morph for Perl
# (https://github.com/openaustralia/morph-docker-perl/blob/master/Dockerfile)
# and all that matters is that your final data is written to an Sqlite
# database called data.sqlite in the current working directory which has at
# least a table called data.
