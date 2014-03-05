use File::Slurp 'read_file';
use Data::Dumper;
use JSON::Tiny;

my @json = split /-{5,}/, read_file('sample.json');

sub json_tiny { return [ map { JSON::Tiny::decode_json $_ } @json ]; }

print Dumper json_tiny();
