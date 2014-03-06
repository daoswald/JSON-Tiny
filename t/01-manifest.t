#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;

plan skip_all => 'Author tests not required for installation.'
  unless $ENV{RELEASE_TESTING};

eval "use Test::CheckManifest 0.9"; ## no critic (eval)
plan skip_all => "Test::CheckManifest 0.9 required" if $@;
ok_manifest();
