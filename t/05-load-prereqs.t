#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 3;

sub message {
  return "*** $_[0] MUST BE INSTALLED BEFORE PROCEEDING ***\n";
}

BEGIN {
  foreach my $module ( qw/Scalar::Util Encode B/ ) {
    use_ok($module) or BAIL_OUT( message($module) );
  }
}
