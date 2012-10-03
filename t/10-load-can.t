#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok( 'JSON::Tiny' ) || BAIL_OUT(); }

diag( "Testing JSON::Tiny $JSON::Tiny::VERSION, Perl $], $^X" );

can_ok( 'JSON::Tiny', qw( new error decode encode true false ) );

done_testing();
