BEGIN { $ENV{PERL_JSON_BACKEND} = 0; } # JSON::PP.

use JSON;
use File::Slurp 'read_file';
use Data::Dumper;

my @json = split /-{5,}/, read_file('sample.json');

sub json_pp { my $j = JSON->new; return [ map { $j->decode($_) } @json ]; }

my $decoded = json_pp();
print Dumper $decoded;
