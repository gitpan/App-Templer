#!/usr/bin/perl -Ilib/ -I../lib/
#
#  Test the execution of file inclusion command via our plugin.
#
#  NOTE: We have to make a Templer::Page object so that source
# is correct.
#
# Steve
# --



use strict;
use warnings;

use Test::More qw! no_plan !;
use File::Temp qw! tempdir !;

#
#  Load the factory
#
BEGIN {use_ok('Templer::Plugin::Factory');}
require_ok('Templer::Plugin::Factory');

#
#  Load the plugin + dependency
#
BEGIN {use_ok('Templer::Site');}
require_ok('Templer::Site');
BEGIN {use_ok('Templer::Site::Page');}
require_ok('Templer::Site::Page');
BEGIN {use_ok('Templer::Plugin::FileContents');}
require_ok('Templer::Plugin::FileContents');


#
#  Create a config file
#
my $site = Templer::Site->new();

#
#  Instantiate the helper.
#
my $factory = Templer::Plugin::Factory->new();
ok( $factory, "Loaded the factory object." );
isa_ok( $factory, "Templer::Plugin::Factory" );

#
#  Create a temporary tree.
#
my $dir = tempdir( CLEANUP => 1 );

#
#  Create a page.
#
open( my $handle, ">", $dir . "/input.wgn" );
print $handle <<EOF;
Title: This is my page title.
Password: read_file( "/etc/passwd" )
Foo: read_file(SELF)
----

This is my page content.

EOF
close($handle);


#
#  Create the page
#
my $page = Templer::Site::Page->new( file => $dir . "/input.wgn" );
ok( $page, "We created a page object" );
isa_ok( $page, "Templer::Site::Page", "Which has the correct type" );


#
#  Get the title to be sure
#
is( $page->field("title"),
    "This is my page title.",
    "The page has the correct title" );

#
#  Get the data, after plugin-expansion
#
my %original = $page->fields();
my $ref      = $factory->expand_variables( $site, $page, \%original );
my %updated  = %$ref;

ok( %updated,               "Fetching the fields of the page succeeded" );
ok( $updated{ 'password' }, "The fields contain a file reference" );
ok( $updated{ 'foo' },      "The fields contain the self-file reference" );

#
# Do the file contents look sane?
#
ok( $updated{ 'password' } =~ /root:/,  "The password file looks sane" );
ok( $updated{ 'foo' }      =~ /passwd/, "The self-file looks sane" );

