package JSON::Tiny;

# Minimalistic JSON. Code and tests adapted from Mojo::JSON and Mojo::Util.

# Licensed under the Artistic 2.0 license.
# http://www.perlfoundation.org/artistic_license_2_0.

use 5.010;
use strict;
use warnings;
use B;
use Exporter 'import';
use Scalar::Util ();
use Encode ();

our $VERSION = '0.28';
our @EXPORT_OK = qw(j);

# Constructor and accessor: we don't have Mojo::Base.

sub new {
  my $class = shift;
  bless @_ ? @_ > 1 ? {@_} : {%{$_[0]}} : {}, $class;
}

sub error {
  $_[0]->{error} = $_[1] if @_ > 1;
  return $_[0]->{error};
}

# The rest adapted from Mojo::JSON, with minor mods & naming changes.

# Literal names
my $FALSE = bless \(my $false = 0), 'JSON::Tiny::_Bool';
my $TRUE  = bless \(my $true  = 1), 'JSON::Tiny::_Bool';

# Escaped special character map (with u2028 and u2029)
my %ESCAPE = (
  '"'     => '"',
  '\\'    => '\\',
  '/'     => '/',
  'b'     => "\x07",
  'f'     => "\x0C",
  'n'     => "\x0A",
  'r'     => "\x0D",
  't'     => "\x09",
  'u2028' => "\x{2028}",
  'u2029' => "\x{2029}"
);
my %REVERSE = map { $ESCAPE{$_} => "\\$_" } keys %ESCAPE;
for (0x00 .. 0x1F, 0x7F) { $REVERSE{pack 'C', $_} //= sprintf '\u%.4X', $_ }

# Unicode encoding detection
my $UTF_PATTERNS = {
  'UTF-32BE' => qr/^\0\0\0[^\0]/,
  'UTF-16BE' => qr/^\0[^\0]\0[^\0]/,
  'UTF-32LE' => qr/^[^\0]\0\0\0/,
  'UTF-16LE' => qr/^[^\0]\0[^\0]\0/
};

my $WHITESPACE_RE = qr/[\x20\x09\x0a\x0d]*/;

sub decode {
  my ($self, $bytes) = @_;

  # Clean start
  $self->error(undef);

  # Missing input
  $self->error('Missing or empty input') and return undef unless $bytes; ## no critic (undef)

  # Remove BOM
  $bytes =~ s/^(?:\357\273\277|\377\376\0\0|\0\0\376\377|\376\377|\377\376)//g;

  # Wide characters
  $self->error('Wide character in input') and return undef ## no critic (undef)
    unless utf8::downgrade($bytes, 1);

  # Detect and decode Unicode
  my $encoding = 'UTF-8';
  $bytes =~ $UTF_PATTERNS->{$_} and $encoding = $_ for keys %$UTF_PATTERNS;

  my $d_res = eval { $bytes = Encode::decode($encoding, $bytes, 1); 1 };
  $bytes = undef unless $d_res;

  # Object or array
  my $res = eval {
    local $_ = $bytes;

    # Leading whitespace
    m/\G$WHITESPACE_RE/gc;

    # Array
    my $ref;
    if (m/\G\[/gc) { $ref = _decode_array() }

    # Object
    elsif (m/\G\{/gc) { $ref = _decode_object() }

    # Unexpected
    else { _exception('Expected array or object') }

    # Leftover data
    unless (m/\G$WHITESPACE_RE\z/gc) {
      my $got = ref $ref eq 'ARRAY' ? 'array' : 'object';
      _exception("Unexpected data after $got");
    }

    $ref;
  };

  # Exception
  if (!$res && (my $e = $@)) {
    chomp $e;
    $self->error($e);
  }

  return $res;
}

sub encode {
  my ($self, $ref) = @_;
  return Encode::encode 'UTF-8', _encode_value($ref);
}

sub false {$FALSE}

sub j {
  my $d = shift;
  return __PACKAGE__->new->encode($d) if ref $d eq 'ARRAY' || ref $d eq 'HASH';
  return __PACKAGE__->new->decode($d);
}

sub true  {$TRUE}

sub _decode_array {
  my @array;
  until (m/\G$WHITESPACE_RE\]/gc) {

    # Value
    push @array, _decode_value();

    # Separator
    redo if m/\G$WHITESPACE_RE,/gc;

    # End
    last if m/\G$WHITESPACE_RE\]/gc;

    # Invalid character
    _exception('Expected comma or right square bracket while parsing array');
  }

  return \@array;
}

sub _decode_object {
  my %hash;
  until (m/\G$WHITESPACE_RE\}/gc) {

    # Quote
    m/\G$WHITESPACE_RE"/gc
      or _exception('Expected string while parsing object');

    # Key
    my $key = _decode_string();

    # Colon
    m/\G$WHITESPACE_RE:/gc
      or _exception('Expected colon while parsing object');

    # Value
    $hash{$key} = _decode_value();

    # Separator
    redo if m/\G$WHITESPACE_RE,/gc;

    # End
    last if m/\G$WHITESPACE_RE\}/gc;

    # Invalid character
    _exception('Expected comma or right curly bracket while parsing object');
  }

  return \%hash;
}

sub _decode_string {
  my $pos = pos;

  # Extract string with escaped characters
  m#\G(((?:[^\x00-\x1F\\"]|\\(?:["\\/bfnrt]|u[[:xdigit:]]{4})){0,32766})*)#gc;
  my $str = $1;

  # Missing quote
  unless (m/\G"/gc) {
    _exception('Unexpected character or invalid escape while parsing string')
      if m/\G[\x00-\x1F\\]/;
    _exception('Unterminated string');
  }

  # Unescape popular characters
  if (index($str, '\\u') < 0) {
    $str =~ s!\\(["\\/bfnrt])!$ESCAPE{$1}!gs;
    return $str;
  }

  # Unescape everything else
  my $buffer = '';
  while ($str =~ m/\G([^\\]*)\\(?:([^u])|u(.{4}))/gc) {
    $buffer .= $1;

    # Popular character
    if ($2) { $buffer .= $ESCAPE{$2} }

    # Escaped
    else {
      my $ord = hex $3;

      # Surrogate pair
      if (($ord & 0xF800) == 0xD800) {

        # High surrogate
        ($ord & 0xFC00) == 0xD800
          or pos($_) = $pos + pos($str), _exception('Missing high-surrogate');

        # Low surrogate
        $str =~ m/\G\\u([Dd][C-Fc-f]..)/gc
          or pos($_) = $pos + pos($str), _exception('Missing low-surrogate');

        # Pair
        $ord = 0x10000 + ($ord - 0xD800) * 0x400 + (hex($1) - 0xDC00);
      }

      # Character
      $buffer .= pack 'U', $ord;
    }
  }

  # The rest
  return $buffer . substr $str, pos($str), length($str);
}

sub _decode_value {

  # Leading whitespace
  m/\G$WHITESPACE_RE/gc;

  # String
  return _decode_string() if m/\G"/gc;

  # Array
  return _decode_array() if m/\G\[/gc;

  # Object
  return _decode_object() if m/\G\{/gc;

  # Number
  return 0 + $1
    if m/\G([-]?(?:0|[1-9][0-9]*)(?:\.[0-9]*)?(?:[eE][+-]?[0-9]+)?)/gc;

  # True
  return $TRUE if m/\Gtrue/gc;

  # False
  return $FALSE if m/\Gfalse/gc;

  # Null
  return undef if m/\Gnull/gc;  ## no critic (return)

  # Invalid data
  _exception('Expected string, array, object, number, boolean or null');
}

sub _encode_array {
  my $array = shift;
  return '[' . join(',', map { _encode_value($_) } @$array) . ']';
}

sub _encode_object {
  my $object = shift;
  my @pairs = map { _encode_string($_) . ':' . _encode_value($object->{$_}) }
    keys %$object;
  return '{' . join(',', @pairs) . '}';
}

sub _encode_string {
  my $str = shift;
  $str =~ s!([\x00-\x1F\x7F\x{2028}\x{2029}\\"/\b\f\n\r\t])!$REVERSE{$1}!gs;
  return "\"$str\"";
}

sub _encode_value {
  my $value = shift;

  # Reference
  if (my $ref = ref $value) {

    # Array
    return _encode_array($value) if $ref eq 'ARRAY';

    # Object
    return _encode_object($value) if $ref eq 'HASH';

    # True or false
    return $$value ? 'true' : 'false' if $ref eq 'SCALAR';
    return $value  ? 'true' : 'false' if $ref eq 'JSON::Tiny::_Bool';

    # Blessed reference with TO_JSON method
    if (Scalar::Util::blessed $value && (my $sub = $value->can('TO_JSON'))) {
      return _encode_value($value->$sub);
    }
  }

  # Null
  return 'null' unless defined $value;

  # Number
  my $flags = B::svref_2object(\$value)->FLAGS;
  return 0 + $value if $flags & (B::SVp_IOK | B::SVp_NOK) && $value * 0 == 0;
 

  # String
  return _encode_string($value);
}

sub _exception {

  # Leading whitespace
  m/\G$WHITESPACE_RE/gc;

  # Context
  my $context = 'Malformed JSON: ' . shift;
  if (m/\G\z/gc) { $context .= ' before end of data' }
  else {
    my @lines = split /\n/, substr($_, 0, pos);
    $context .= ' at line ' . @lines . ', offset ' . length(pop @lines || '');
  }

  die "$context\n";
}

# Emulate boolean type
package JSON::Tiny::_Bool;
use overload '0+' => sub { ${$_[0]} }, '""' => sub { ${$_[0]} }, fallback => 1;

1;
