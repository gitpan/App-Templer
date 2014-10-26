#!/usr/bin/perl -Ilib/ -I../lib/ -w
#
# Test we only expand the variables in a page once.
#
# Steve
#


use strict;
use warnings;

use Test::More qw! no_plan !;


#
#  Simple class is a plugin that appends "BOO" to the value of any key.
#
package Simple::Class;

sub new
{
    my $class = shift;
    bless {}, $class;
}

sub expand_variables
{
    my ( $self, $site, $page, $data ) = (@_);

    my %hash = %$data;
    foreach my $key ( keys %hash )
    {
        $hash{ $key } = $hash{ $key } . "BOO";
    }
    return ( \%hash );
}
Templer::Plugin::Factory->new()->register_plugin("Simple::Class");




package main;

BEGIN {use_ok('Templer::Site');}
require_ok('Templer::Site');
BEGIN {use_ok('Templer::Plugin::Factory');}
require_ok('Templer::Plugin::Factory');
BEGIN {use_ok('Templer::Site::Page');}
require_ok('Templer::Site::Page');


#
#  The config object.
#
my $site = Templer::Site->new();


#
#  Instantiate the helper.
#
my $factory = Templer::Plugin::Factory->new();
ok( $factory, "Loaded the factory object." );
isa_ok( $factory, "Templer::Plugin::Factory" );

#
#  Create a page
#
my $page = Templer::Site::Page->new(
                                 "foo"     => "bar",
                                 "layout"  => "default.layout",
                                 "content" => "<p>This is my page content.</p>",
                                 "title"   => "This is the page title."
);

ok( $page, "Page found" );
isa_ok( $page, "Templer::Site::Page", "And has the correct type" );
is( $page->layout(), "default.layout", "The page has the correct layout" );
is( $page->content(),
    "<p>This is my page content.</p>",
    "The page has the correct content" );
ok( !$page->dependencies(), "The stub page has no dependencies" );

#
#  Get the title, and ensure it is OK.
#
is( $page->field("title"),
    "This is the page title.",
    "The page title matches what we expect" );

#
#  Get the fields - which will be expanded by our plugin.
#
my %original = $page->fields();

my $plugin  = Templer::Plugin::Factory->new();
my $ref     = $plugin->expand_variables( $site, $page, \%original );
my %updated = %$ref;

is( $updated{ 'title' },
    "This is the page title.BOO",
    "The field was expanded"
  );
is( $updated{ 'foo' }, "barBOO", "The field was expanded" );

