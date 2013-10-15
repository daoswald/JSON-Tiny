
use strict;
use warnings;
no warnings 'once';
use Test::More;
use JSON::Tiny;

my $j = JSON::Tiny->new;

ok(1);

my $rv = $j->decode( '{ "a":false, "b":true }' );

ok(
  $rv->{'a'}->isa('JSON::Tiny::_Bool'),
  'Decoding a "false" Boolean gives a JSON::Tiny::_Bool object.'
);

ok(
  $rv->{'b'}->isa('JSON::Tiny::_Bool'),
  'Decoding a "true" Boolean gives a JSON::Tiny::_Bool object.'
);

is(
  ref( $rv->{'a'} ), 'JSON::Tiny::_Bool',
  'ref detects JSON::Tiny::_Bool'
);
is(
  ref( $rv->{'b'} ), 'JSON::Tiny::_Bool',
  'ref detects JSON::Tiny::_Bool type (true)'
);



$JSON::Tiny::FALSE = 0;
$JSON::Tiny::TRUE  = 1;

$rv = $j->decode( '{"a":false, "b":true}' );

is( $rv->{'a'}, 0, 'Overridden Boolean false returns zero (0)' );
is( $rv->{'b'}, 1, 'Overridden Boolean true returns one (1)' );

is(
  ref( $rv->{'a'} ), '',
  'Overriding Boolean false assumes correct type.'
);

is(
  ref( $rv->{'b'} ), '',
  'Overriding Boolean true assumes correct type.'
);

done_testing();
