BEGIN { $ENV{PERL_JSON_BACKEND} = 0; } # JSON::PP.

use File::Slurp 'read_file';
use JSON;
use JSON::Tiny;
use Benchmark 'cmpthese';

my @json = split /-{5,}/, read_file('sample.json');

sub json_pp {
  my $j = JSON->new->relaxed;
  return [ map { $j->decode($_) } @json ];
}

sub json_tiny {
  return [ map { JSON::Tiny::decode_json $_ } @json ];
}

cmpthese ( -15, { JSON_PP => \&json_pp, JSON_Tiny => \&json_tiny } );
