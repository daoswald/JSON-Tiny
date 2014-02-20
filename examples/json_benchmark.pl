BEGIN { $ENV{PERL_JSON_BACKEND} = 0; } # Force JSON::PP.

use File::Slurp 'read_file';
use JSON;
use JSON::Tiny;
use Benchmark qw( cmpthese );

my @json = split /-{5,}/, read_file('sample.json');

sub json_pp {
  my $j = JSON->new->relaxed;
  return [ map { $j->decode($_) } @json ];
}

sub json_tiny {
  my $j = JSON::Tiny->new;
  return [ map { $j->decode($_) } @json ];
}

cmpthese ( -15, { JSON_PP => \&json_pp, JSON_Tiny => \&json_tiny } );
