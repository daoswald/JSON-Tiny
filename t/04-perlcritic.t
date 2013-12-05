#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use English qw( -no_match_vars );

if ( not $ENV{RELEASE_TESTING} ) {
  my $msg = 'Author Test: Set $ENV{RELEASE_TESTING} to a true value to run.';
  plan( skip_all => $msg );
}

# We also don't want to force a dependency on Test::Perl::Critic, so if the
# user doesn't have the module, we won't run the test.

eval { require Test::Perl::Critic; }; ## no critic (eval)

if ( $EVAL_ERROR ) {
  my $msg = 'Author Test: Test::Perl::Critic required to criticise code.';
  plan( skip_all => $msg );
}

Test::Perl::Critic->import( -severity => 5 );

my @directories = qw{  blib/  t/  };

Test::Perl::Critic::all_critic_ok(@directories);
