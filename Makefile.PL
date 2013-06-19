## no critic (RCS,VERSION,may require interpolation)

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
  NAME              => 'JSON::Tiny',
  AUTHOR            => q{David Oswald <davido [at] cpan [d.o.t] org>},
  VERSION_FROM      => 'lib/JSON/Tiny.pm',
  ABSTRACT_FROM     => 'lib/JSON/Tiny.pod',
  LICENSE           => 'artistic_2',
  MIN_PERL_VERSION  => '5.008004',
  PL_FILES          => {},
  BUILD_REQUIRES => { 'Test::More' => '0.98' },
  META_MERGE => {
    provides => {
      'JSON::Tiny' => {
        file    => 'lib/JSON/Tiny.pm',
        version => '0.30'
      },
    },
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'JSON-Tiny-*' },
);
