#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

sub prereq_message {
    return "*** YOU MUST INSTALL $_[0] BEFORE PROCEEDING ***\n";
}

BEGIN {
    foreach my $module ( qw/Scalar::Util Encode B/ ) {
        use_ok( $module )
            or BAIL_OUT( prereq_message( $module ) );
    }
}

done_testing();
