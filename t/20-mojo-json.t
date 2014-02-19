package JSONTest; ## no critic (package)

use strict;

# Emulate Mojo::Base -base.

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, $class;
}

sub something {
  my $self = shift;
  $self->{something} = shift if @_;
  $self->{something} = {}    if ! defined $self->{something};
  return $self->{something};
}

sub TO_JSON { shift->something }

package main;

use strict;
use utf8;
use Encode qw( encode decode );
use Test::More;

plan tests => 136;  # One blessed reference test disabled: Difficult without
                    # Mojo::ByteStream & Mojo::Base. Other blessed reference
                    # tests still exist.

use JSON::Tiny qw(decode_json encode_json j);

# Decode array
my $json  = JSON::Tiny->new;
my $array = $json->decode('[]');
is_deeply $array, [], 'decode []';
$array = $json->decode('[ [ ]]');
is_deeply $array, [[]], 'decode [ [ ]]';

# Decode number
$array = $json->decode('[0]');
is_deeply $array, [0], 'decode [0]';
$array = $json->decode('[1]');
is_deeply $array, [1], 'decode [1]';
$array = $json->decode('[ "-122.026020" ]');
is_deeply $array, ['-122.026020'], 'decode [ -122.026020 ]';
$array = $json->decode('[ -122.026020 ]');
is_deeply $array, ['-122.02602'], 'decode [ -122.026020 ]';
$array = $json->decode('[0.0]');
cmp_ok $array->[0], '==', 0, 'value is 0';
$array = $json->decode('[0e0]');

cmp_ok $array->[0], '==', 0, 'value is 0';
$array = $json->decode('[1,-2]');
is_deeply $array, [1, -2], 'decode [1,-2]';
$array = $json->decode('["10e12" , [2 ]]');
is_deeply $array, ['10e12', [2]], 'decode ["10e12" , [2 ]]';
$array = $json->decode('[10e12 , [2 ]]');
is_deeply $array, [10000000000000, [2]], 'decode [10e12 , [2 ]]';
$array = $json->decode('[37.7668 , [ 20 ]] ');
is_deeply $array, [37.7668, [20]], 'decode [37.7668 , [ 20 ]] ';
$array = $json->decode('[1e3]');
cmp_ok $array->[0], '==', 1e3, 'value is 1e3';

# Decode name
$array = $json->decode('[true]');
is_deeply $array, [JSON::Tiny->true], 'decode [true]';
$array = $json->decode('[null]');
is_deeply $array, [undef], 'decode [null]';
$array = $json->decode('[true, false]');
is_deeply $array, [JSON::Tiny->true, JSON::Tiny->false], 'decode [true, false]';

# Decode string
$array = $json->decode('[" "]');
is_deeply $array, [' '], 'decode [" "]';
$array = $json->decode('["hello world!"]');
is_deeply $array, ['hello world!'], 'decode ["hello world!"]';
$array = $json->decode('["hello\nworld!"]');
is_deeply $array, ["hello\nworld!"], 'decode ["hello\nworld!"]';
$array = $json->decode('["hello\t\"world!"]');
is_deeply $array, ["hello\t\"world!"], 'decode ["hello\t\"world!"]';
$array = $json->decode('["hello\u0152world\u0152!"]');
is_deeply $array, ["hello\x{0152}world\x{0152}!"],
  'decode ["hello\u0152world\u0152!"]';
$array = $json->decode('["0."]');
is_deeply $array, ['0.'], 'decode ["0."]';
$array = $json->decode('[" 0"]');
is_deeply $array, [' 0'], 'decode [" 0"]';
$array = $json->decode('["1"]');
is_deeply $array, ['1'], 'decode ["1"]';
$array = $json->decode('["\u0007\b\/\f\r"]');
is_deeply $array, ["\a\b/\f\r"], 'decode ["\u0007\b\/\f\r"]';


# Decode object
my $hash = $json->decode('{}');
is_deeply $hash, {}, 'decode {}';
$hash = $json->decode('{"foo": "bar"}');
is_deeply $hash, {foo => 'bar'}, 'decode {"foo": "bar"}';
$hash = $json->decode('{"foo": [23, "bar"]}');
is_deeply $hash, {foo => [qw(23 bar)]}, 'decode {"foo": [23, "bar"]}';

# Decode full spec example
$hash = $json->decode(<<EOF);
{
   "Image": {
       "Width":  800,
       "Height": 600,
       "Title":  "View from 15th Floor",
       "Thumbnail": {
           "Url":    "http://www.example.com/image/481989943",
           "Height": 125,
           "Width":  "100"
       },
       "IDs": [116, 943, 234, 38793]
    }
}
EOF
is $hash->{Image}{Width},  800,                    'right value';
is $hash->{Image}{Height}, 600,                    'right value';
is $hash->{Image}{Title},  'View from 15th Floor', 'right value';
is $hash->{Image}{Thumbnail}{Url}, 'http://www.example.com/image/481989943',
  'right value';
is $hash->{Image}{Thumbnail}{Height}, 125, 'right value';
is $hash->{Image}{Thumbnail}{Width},  100, 'right value';
is $hash->{Image}{IDs}[0], 116,   'right value';
is $hash->{Image}{IDs}[1], 943,   'right value';
is $hash->{Image}{IDs}[2], 234,   'right value';
is $hash->{Image}{IDs}[3], 38793, 'right value';

# Encode array
my $bytes = $json->encode([]);
is $bytes, '[]', 'encode []';
$bytes = $json->encode([[]]);
is $bytes, '[[]]', 'encode [[]]';
$bytes = $json->encode([[], []]);
is $bytes, '[[],[]]', 'encode [[], []]';
$bytes = $json->encode([[], [[]], []]);
is $bytes, '[[],[[]],[]]', 'encode [[], [[]], []]';

# Encode string
$bytes = $json->encode(['foo']);
is $bytes, '["foo"]', 'encode [\'foo\']';
$bytes = $json->encode(["hello\nworld!"]);
is $bytes, '["hello\nworld!"]', 'encode ["hello\nworld!"]';
$bytes = $json->encode(["hello\t\"world!"]);
is $bytes, '["hello\t\"world!"]', 'encode ["hello\t\"world!"]';
$bytes = $json->encode(["hello\x{0003}\x{0152}world\x{0152}!"]);
is decode('UTF-8', $bytes), "[\"hello\\u0003\x{0152}world\x{0152}!\"]",
  'encode ["hello\x{0003}\x{0152}world\x{0152}!"]';
$bytes = $json->encode(["123abc"]);
is $bytes, '["123abc"]', 'encode ["123abc"]';
$bytes = $json->encode(["\a\b/\f\r"]);
is $bytes, '["\\u0007\\b\/\f\r"]', 'encode ["\a\b/\f\r"]';
  


# Encode object
$bytes = $json->encode({});
is $bytes, '{}', 'encode {}';
$bytes = $json->encode({foo => {}});
is $bytes, '{"foo":{}}', 'encode {foo => {}}';
$bytes = $json->encode({foo => 'bar'});
is $bytes, '{"foo":"bar"}', 'encode {foo => \'bar\'}';
$bytes = $json->encode({foo => []});
is $bytes, '{"foo":[]}', 'encode {foo => []}';
$bytes = $json->encode({foo => ['bar']});
is $bytes, '{"foo":["bar"]}', 'encode {foo => [\'bar\']}';

# Encode name
$bytes = $json->encode([$json->true]);
is $bytes, '[true]', 'encode [JSON::Tiny->true]';
$bytes = $json->encode([undef]);
is $bytes, '[null]', 'encode [undef]';
$bytes = $json->encode([JSON::Tiny->true, JSON::Tiny->false]);
is $bytes, '[true,false]', 'encode [JSON::Tiny->true, JSON::Tiny->false]';

# Encode number
$bytes = $json->encode([1]);
is $bytes, '[1]', 'encode [1]';
$bytes = $json->encode(["1"]);
is $bytes, '["1"]', 'encode ["1"]';
$bytes = $json->encode(['-122.026020']);
is $bytes, '["-122.026020"]', 'encode [\'-122.026020\']';
$bytes = $json->encode([-122.026020]);
is $bytes, '[-122.02602]', 'encode [-122.026020]';
$bytes = $json->encode([1, -2]);
is $bytes, '[1,-2]', 'encode [1, -2]';
$bytes = $json->encode(['10e12', [2]]);
is $bytes, '["10e12",[2]]', 'encode [\'10e12\', [2]]';
$bytes = $json->encode([10e12, [2]]);
is $bytes, '[10000000000000,[2]]', 'encode [10e12, [2]]';
$bytes = $json->encode([37.7668, [20]]);
is $bytes, '[37.7668,[20]]', 'encode [37.7668, [20]]';

# Faihu roundtrip
#$bytes = $json->encode(["\x{10346}"]);
$bytes = j(["\x{10346}"]);
is decode( 'UTF-8', $bytes ), "[\"\x{10346}\"]", 'encode ["\x{10346}"]';
#$array = $json->decode($bytes);
$array = j($bytes);
is_deeply $array, ["\x{10346}"], 'successful roundtrip';




# Decode UTF-16LE
$array = $json->decode( encode( 'UTF-16LE', "\x{feff}[true]" ));
is_deeply $array, [JSON::Tiny->true], 'decode \x{feff}[true]';

# Decode UTF-16LE with faihu surrogate pair
$array = $json->decode( encode('UTF-16LE', "\x{feff}[\"\\ud800\\udf46\"]"));
is_deeply $array, ["\x{10346}"], 'decode \x{feff}[\"\\ud800\\udf46\"]';

# Decode UTF-16LE with faihu surrogate pair and BOM value
$array = $json->decode(
  encode( 'UTF-16LE', "\x{feff}[\"\\ud800\\udf46\x{feff}\"]" ));
is_deeply $array, ["\x{10346}\x{feff}"],
  'decode \x{feff}[\"\\ud800\\udf46\x{feff}\"]';

# Decode UTF-16BE with faihu surrogate pair
$array = $json->decode(encode('UTF-16BE', "\x{feff}[\"\\ud800\\udf46\"]"));
is_deeply $array, ["\x{10346}"], 'decode \x{feff}[\"\\ud800\\udf46\"]';

# Decode UTF-32LE
$array = $json->decode(encode('UTF-32LE', "\x{feff}[true]"));
is_deeply $array, [JSON::Tiny->true], 'decode \x{feff}[true]';

# Decode UTF-32BE
$array = $json->decode(encode('UTF-32BE', "\x{feff}[true]"));
is_deeply $array, [JSON::Tiny->true], 'decode \x{feff}[true]';

# Decode UTF-16LE without BOM
$array
  = $json->decode(encode('UTF-16LE', "[\"\\ud800\\udf46\"]"));
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode UTF-16BE without BOM
$array
  = $json->decode(encode('UTF-16BE', "[\"\\ud800\\udf46\"]"));
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode UTF-32LE without BOM
$array
  = $json->decode(encode('UTF-32LE', "[\"\\ud800\\udf46\"]"));
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode UTF-32BE without BOM
$array
  = $json->decode(encode('UTF-32BE', "[\"\\ud800\\udf46\"]"));
is_deeply $array, ["\x{10346}"], 'decode [\"\\ud800\\udf46\"]';

# Decode object with duplicate keys
$hash = $json->decode('{"foo": 1, "foo": 2}');
is_deeply $hash, {foo =>2}, 'decode {"foo": 1, "foo": 2}';

# Complicated roudtrips
$bytes = '{"":""}';
$hash  = $json->decode($bytes);
is_deeply $hash, {'' => ''}, 'decode {"":""}';
is $json->encode($hash), $bytes, 'reencode';
$bytes = '[null,false,true,"",0,1]';
$array  = $json->decode($bytes);
is_deeply $array, [undef, JSON::Tiny->false, JSON::Tiny->true, '', 0, 1],
  'decode [null,false,true,"",0,1]';
is $json->encode($array), $bytes, 'reencode';
$array = [undef, 0, 1, '', JSON::Tiny->true, JSON::Tiny->false];
$bytes = $json->encode($array);
ok $bytes, 'defined value';
is_deeply $json->decode($bytes), $array, 'successful roundtrip';

# Real world roundtrip
$bytes = encode_json({foo => 'c:\progra~1\mozill~1\firefox.exe'});
is $bytes, '{"foo":"c:\\\\progra~1\\\\mozill~1\\\\firefox.exe"}',
  'encode {foo => \'c:\progra~1\mozill~1\firefox.exe\'}';
$hash = decode_json($bytes);
is_deeply $hash, {foo => 'c:\progra~1\mozill~1\firefox.exe'},
  'successful roundtrip';

# Huge string
$bytes = $json->encode(['a' x 32768]);
is_deeply $json->decode($bytes), ['a' x 32768], 'successful roundtrip (huge)'; # segfault under 5.8.x.
is $json->error, undef, 'no error';

# u2028 and u2029
$bytes = $json->encode(["\x{2028}test\x{2029}123"]);
is index($bytes, encode('UTF-8',"\x{2028}")), -1,'properly escaped';
is index($bytes, encode('UTF-8',"\x{2029}")), -1, 'properly escaped';
is_deeply $json->decode($bytes), ["\x{2028}test\x{2029}123"],
  'successful roundtrip';

# Mojo::ByteStream::b() not available, and can't be reasonably simulated.
# Blessed reference
# $bytes = $json->encode([b('test')]);
# is_deeply $json->decode($bytes), ['test'], 'successful roundtrip';

# Blessed reference with TO_JSON method
$bytes = $json->encode(JSONTest->new);
is_deeply $json->decode($bytes), {}, 'successful roundtrip';
$bytes = $json->encode(
  JSONTest->new(something => {just => 'works'}, else => {not => 'working'}));
is_deeply $json->decode($bytes), {just => 'works'}, 'successful roundtrip';

# Boolean shortcut
is $json->encode({true  => \1}), '{"true":true}',   'encode {true => \1}';
is $json->encode({false => \0}), '{"false":false}', 'encode {false => \0}';
$bytes = 'some true value';
is $json->encode({true => \!!$bytes}), '{"true":true}',
  'encode true boolean from double negated reference';
is $json->encode({true => \$bytes}), '{"true":true}',
  'encode true boolean from reference';
$bytes = '';
is $json->encode({false => \!!$bytes}), '{"false":false}',
  'encode false boolean from double negated reference';
is $json->encode({false => \$bytes}), '{"false":false}',
  'encode false boolean from reference';

# Upgraded numbers
my $num = 3;
my $str = "$num";
is $json->encode({test => [$num, $str]}), '{"test":[3,"3"]}',
  'upgraded number detected';
$num = 3.21;
$str = "$num";
is $json->encode({test => [$num, $str]}), '{"test":[3.21,"3.21"]}',
  'upgraded number detected';
$str = '0 but true';
$num = 1 + $str;
is $json->encode({test => [$num, $str]}), '{"test":[1,0]}',
  'upgraded number detected';

# "inf" and "nan"
like $json->encode({test => 9**9**9}), qr/^{"test":".*"}$/,
  'encode "inf" as string';
like $json->encode({test => -sin(9**9**9)}), qr/^{"test":".*"}$/,
  'encode "nan" as string';

# Errors
is $json->decode('["â™¥"]'), undef, 'wide character in input';
is $json->error, 'Wide character in input', 'right error';
is $json->decode(encode('UTF-16LE',"\x{feff}[\"\\ud800\"]")), undef,
  'missing high surrogate';
is $json->error, 'Malformed JSON: Missing low-surrogate at line 1, offset 8',
  'right error';
is $json->decode(encode('UTF-16LE', "\x{feff}[\"\\udf46\"]")), undef,
  'missing low surrogate';
is $json->error, 'Malformed JSON: Missing high-surrogate at line 1, offset 8',
  'right error';
is $json->decode('[[]'), undef, 'missing right square bracket';
is $json->error, 'Malformed JSON: Expected comma or right square bracket while'
  . ' parsing array at line 1, offset 3', 'right error';
is $json->decode('{{}'), undef, 'missing right curly bracket';
is $json->error, 'Malformed JSON: Expected string while'
  . ' parsing object at line 1, offset 1', 'right error';
is $json->decode('[[]...'), undef, 'syntax error';
is $json->error, 'Malformed JSON: Expected comma or right square bracket while'
  . ' parsing array at line 1, offset 3', 'right error';
is $json->decode('{{}...'), undef, 'syntax error';
is $json->error, 'Malformed JSON: Expected string while'
  . ' parsing object at line 1, offset 1', 'right error';
is $json->decode('[nan]'), undef, 'syntax error';
is $json->error, 'Malformed JSON: Expected string, array, object, number,'
  . ' boolean or null at line 1, offset 1', 'right error';
is $json->decode('["foo]'), undef, 'syntax error';
is $json->error, 'Malformed JSON: Unterminated string at line 1, offset 6',
  'right error';
is $json->decode('["foo"]lala'), undef, 'syntax error';
is $json->error,
  'Malformed JSON: Unexpected data after array at line 1, offset 7',
  'right error';
is $json->decode('false'), undef, 'no object or array';
is $json->error,
  'Malformed JSON: Expected array or object at line 0, offset 0',
  'right error';
is $json->decode(encode('Shift_JIS', 'やった')), undef, 'invalid encoding';
is $json->error,
  'Malformed JSON: Expected array or object at line 0, offset 0',
  'right error';
is $json->decode(''), undef, 'no object or array';
is $json->error, 'Missing or empty input', 'right error';
is $json->decode("[\"foo\",\n\"bar\"]lala"), undef, 'syntax error';
is $json->error,
  'Malformed JSON: Unexpected data after array at line 2, offset 6',
  'right error';
is $json->decode("[\"foo\",\n\"bar\",\n\"bazra\"]lalala"), undef,
  'syntax error';
is $json->error,
  'Malformed JSON: Unexpected data after array at line 3, offset 8',
  'right error';
is $json->decode('0'), undef, 'syntax error';
is $json->error,
  'Malformed JSON: Expected array or object at line 0, offset 0',
  'right error';
my $jt = eval { j('{') }, undef, 'decoding failed';
eval { decode_json("[\"foo\",\n\"bar\",\n\"bazra\"]lalala") };
like $@,
  qr/JSON: Unexpected data after array at line 3, offset 8 at.*json\.t/,
  'right error';
