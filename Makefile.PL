## no critic (RCS,VERSION,may require interpolation)

use strict;
use warnings;
use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'JSON::Tiny',
  AUTHOR            => q{David Oswald <davido [at] cpan [d.o.t] org>},
  VERSION_FROM      => 'lib/JSON/Tiny.pm',
  ABSTRACT_FROM     => 'lib/JSON/Tiny.pod',
  LICENSE           => 'artistic_2',
  MIN_PERL_VERSION  => '5.010000',
  PL_FILES          => {},
  # All are core-only.
  BUILD_REQUIRES => {
    'Test::More' => '0.98',
    'English'    => '0',
  },
  PREREQ_PM => {
    'Exporter'     => '0',
    'Scalar::Util' => '0',
    'B'            => '0',
    'Encode'       => '0',
  },
  META_MERGE => {
    provides => {
      'JSON::Tiny' => {
        file    => 'lib/JSON/Tiny.pm',
        version => '0.27'
      },
    },
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'JSON-Tiny-*' },
);
