## no critic (RCS,VERSION,may require interpolation)

use 5.008000;
use strict;
use warnings;
use ExtUtils::MakeMaker;

my $PREREQ_PM = {};

$PREREQ_PM->{'Test::More'}   = '0'    if $] < 5.006002; #BUILD_REQUIRES N/A.
$PREREQ_PM->{'Scalar::Util'} = '0'    if $] < 5.008000;
$PREREQ_PM->{'Encode'}       = '0'    if $] < 5.008000;
$PREREQ_PM->{'Exporter'}     = '5.59' if $] < 5.008004;

WriteMakefile(
  NAME              => 'JSON::Tiny',
  AUTHOR            => q{David Oswald <davido [at] cpan [d.o.t] org>},
  VERSION_FROM      => 'lib/JSON/Tiny.pm',
  ABSTRACT_FROM     => 'lib/JSON/Tiny.pod',
  LICENSE           => 'artistic_2',
  MIN_PERL_VERSION  => '5.008000',
  PL_FILES          => {},
  PREREQ_PM         => $PREREQ_PM,
  META_MERGE => {
    'meta-spec'		=> { version => 2 },
    resources			=> {
			repository		=> {
				type		=> 'git',
				url			=> 'https://github.com/daoswald/JSON-Tiny.git',
				web			=> 'https://github.com/daoswald/JSON-Tiny',
			},
		},
    provides => {
      'JSON::Tiny' => {
        file    => 'lib/JSON/Tiny.pm',
        version => '0.35'
      },
    },
  },
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
  clean => { FILES    => 'JSON-Tiny-*' },
);
