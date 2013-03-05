## no critic (RCS,VERSION,may require interpolation)

use strict;
use warnings;
use 5.010000;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'JSON::Tiny',
  AUTHOR            => q{David Oswald <davido [@at] cpan [d.o.t] org>},
  VERSION_FROM      => 'lib/JSON/Tiny.pm',
  ABSTRACT_FROM     => 'lib/JSON/Tiny.pod',
  LICENSE           => 'artistic_2',
  MIN_PERL_VERSION  => '5.010000',
  PL_FILES          => {},
  BUILD_REQUIRES => {
    'Test::More' => '0.98',  # Core; updated version.
    'English'    => '0',     # Core.
  },
  PREREQ_PM => {
    'Exporter'     => '0',   # Core.
    'Scalar::Util' => '0',   # Core.
    'B'            => '0',   # Core.
    'Encode'       => '0',   # Core.
  },
  META_MERGE => {
    provides => {
      'JSON::Tiny' => {
        file    => 'lib/JSON/Tiny.pm',
        version => '0.25'
      },
    },
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'JSON-Tiny-*' },
);
