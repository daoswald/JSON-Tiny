package JSON::Tiny;

# Minimalistic JSON encoding and decoding.  The code is directly copied from
# Mojo::JSON and Mojo::Util (version 3.43) with a few minor adjustments to
# facilitate its use as a stand-alone tool.

use B;
use Scalar::Util 'blessed';
use Encode ();

# Constructor and accessor since we're not using Mojo::Base.
sub new {
  my $self = bless {}, shift;
  $self->{error} = undef;
  return $self;
}

sub error {
  $_[0]->{error} = $_[1] if @_ > 1;
  return $_[0]->{error};
}


# Utilities that would have been provided by Mojo::Util.

sub JSON::Tiny::Util::decode {
  my ($encoding, $bytes) = @_;
  return unless eval { $bytes = Encode::decode($encoding, $bytes, 1); 1 };
  return $bytes;
}

sub JSON::Tiny::Util::encode { Encode::encode(shift, shift) }



# The rest of this was lifted from Mojo::JSON, with a few name changes to fit
# the new standalone package.

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

  # Cleanup
  $self->error(undef);

  # Missing input
  $self->error('Missing or empty input') and return unless $bytes;

  # Remove BOM
  $bytes =~ s/^(?:\357\273\277|\377\376\0\0|\0\0\376\377|\376\377|\377\376)//g;

  # Wide characters
  $self->error('Wide character in input') and return
    unless utf8::downgrade($bytes, 1);

  # Detect and decode Unicode
  my $encoding = 'UTF-8';
  $bytes =~ $UTF_PATTERNS->{$_} and $encoding = $_ for keys %$UTF_PATTERNS;
  $bytes = JSON::Tiny::Util::decode $encoding, $bytes;

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
  return JSON::Tiny::Util::encode 'UTF-8', _encode_values($ref);
}

sub false {$FALSE}
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
  return undef if m/\Gnull/gc;

  # Invalid data
  _exception('Expected string, array, object, number, boolean or null');
}

sub _encode_array {
  return '[' . join(',', map { _encode_values($_) } @{shift()}) . ']';
}

sub _encode_object {
  my $object = shift;

  # Encode pairs
  my @pairs = map { _encode_string($_) . ':' . _encode_values($object->{$_}) }
    keys %$object;

  # Stringify
  return '{' . join(',', @pairs) . '}';
}

sub _encode_string {
  my $string = shift;

  # Escape string
  $string =~ s!([\x00-\x1F\x7F\x{2028}\x{2029}\\"/\b\f\n\r\t])!$REVERSE{$1}!gs;

  # Stringify
  return "\"$string\"";
}

sub _encode_values {
  my $value = shift;

  # Reference
  if (my $ref = ref $value) {

    # Array
    return _encode_array($value) if $ref eq 'ARRAY';

    # Object
    return _encode_object($value) if $ref eq 'HASH';

    # True or false
    return $value ? 'true' : 'false' if $ref eq 'JSON::Tiny::_Bool';

    # Blessed reference with TO_JSON method
    if (blessed $value && (my $sub = $value->can('TO_JSON'))) {
      return _encode_values($value->$sub);
    }
  }

  # Null
  return 'null' unless defined $value;

  # Number
  my $flags = B::svref_2object(\$value)->FLAGS;
  return $value
    if $flags & (B::SVp_IOK | B::SVp_NOK) && !($flags & B::SVp_POK);

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

  # Throw
  die "$context\n";
}

# Emulate boolean type
package JSON::Tiny::_Bool;
use overload '0+' => sub { ${$_[0]} }, '""' => sub { ${$_[0]} }, fallback => 1;

1;

=head1 NAME

JSON::Tiny - Minimalistic JSON (A derivative work from JSON::Tiny).

=head1 SYNOPSIS

  use JSON::Tiny;

  my $json  = JSON::Tiny->new;
  my $bytes = $json->encode({foo => [1, 2], bar => 'hello!'});
  my $hash  = $json->decode($bytes);

=head1 DESCRIPTION

L<JSON::Tiny> is a standalone adaptation of L<Mojo::JSON>, from the fabulous
L<Mojolicious> "web in a box" framework.

L<JSON::Tiny> is a minimalistic and relaxed implementation of RFC 4627. While
it is possibly the fastest pure-Perl JSON parser available, you should not use
it for validation.

It supports normal Perl data types like C<Scalar>, C<Array> reference, C<Hash>
reference and will try to call the C<TO_JSON> method on blessed references, or
stringify them if it doesn't exist.

  [1, -2, 3]     -> [1, -2, 3]
  {"foo": "bar"} -> {foo => 'bar'}

Literal names will be translated to and from L<JSON::Tiny> constants or a
similar native Perl value.

  true  -> JSON::Tiny->true
  false -> JSON::Tiny->false
  null  -> undef

Decoding UTF-16 (LE/BE) and UTF-32 (LE/BE) will be handled transparently,
encoding will only generate UTF-8. The two Unicode whitespace characters
C<u2028> and C<u2029> will always be escaped to make JSONP easier.

=head1 ATTRIBUTES

L<JSON::Tiny> implements the following attributes.

=head2 C<error>

  my $err = $json->error;
  $json   = $json->error('Parser error');

Parser errors.

=head1 METHODS

L<JSON::Tiny> implements the following methods.

=head2 C<decode>

  my $array = $json->decode($bytes);
  my $hash  = $json->decode($bytes);

Decode JSON.

=head2 C<encode>

  my $bytes = $json->encode({foo => 'bar'});

Encode Perl data structure.

=head2 C<false>

  my $false = JSON::Tiny->false;
  my $false = $json->false;

False value, used because Perl has no native equivalent.

=head2 C<true>

  my $true = JSON::Tiny->true;
  my $true = $json->true;

True value, used because Perl has no native equivalent.

=head1 SEE ALSO

L<Mojolicious>, L<Mojo::JSON>.

=cut
