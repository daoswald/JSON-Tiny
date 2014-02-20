use File::Slurp 'read_file';
use Data::Dumper;
use JSON::Tiny 'decode_json';

my @json = split /-{5,}/, read_file('sample.json');

sub json_tiny {
  return [ map { decode_json($_) } @json ];
}

my $decoded = json_tiny();
print Dumper $decoded;
