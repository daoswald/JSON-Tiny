#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;
use File::Slurp;
use JSON::Tiny;
use feature qw/say/;

my $json = read_file(\*DATA);

my $j = JSON::Tiny->new;

my $decoded = $j->decode($json);
say Dumper $decoded;

say $decoded->{stock}{warehouse};

__DATA__
{
    "id": 1,
    "name": "Foo",
    "price": 123,
    "tags": [ "Bar", "Eek" ],
    "stock": {
        "warehouse": 300,
        "retail": 20
    }
}
