use strict;
use warnings;
use Test::More tests => 1;
use JSON::Tiny 'j';

eval { my $decoded = j('[[]') };
like( $@, qr/^Malformed JSON: Expected comma or right square bracket/,
  'j() dies on parsing error with correct error'
);
