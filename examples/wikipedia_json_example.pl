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

say "ID Required." if $decoded->{properties}{id}{required};
say "ID Type: ", $decoded->{properties}{id}{type};

__DATA__
{
    "name": "Product",
    "properties": {
        "id": {
            "type": "number",
            "description": "Product identifier",
            "required": true
        },
        "name": {
            "type": "string",
            "description": "Name of the product",
            "required": true
        },
        "price": {
            "type": "number",
            "minimum": 0,
            "required": true
        },
        "tags": {
            "type": "array",
            "items": {
                "type": "string"
            }
        },
        "stock": {
            "type": "object",
            "properties": {
                "warehouse": {
                    "type": "number"
                },
                "retail": {
                    "type": "number"
                }
            }
        }
    }
}

