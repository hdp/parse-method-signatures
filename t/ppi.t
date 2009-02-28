use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Test::Differences;

use_ok("Parse::Method::Signatures") or BAIL_OUT("$@");

is( Parse::Method::Signatures->new("ArrayRef")->_ident(), "ArrayRef");
is( Parse::Method::Signatures->new("where::Foo")->_ident(), "where::Foo");

{ local $TODO = "sort out lextable";
is( Parse::Method::Signatures->new("where Foo")->_ident(), undef);
}

throws_ok {
  Parse::Method::Signatures->new("Foo[Bar")->tc()
} qr/^\QRunaway '[]' in type constraint near '[Bar' at\E/,
  q/Runaway '[]' in type constraint near '[Bar' at/;

throws_ok {
  Parse::Method::Signatures->new("Foo[Bar:]")->tc()
} qr/^\QError parsing type constraint near 'Bar:' in 'Bar:' at\E/,
  q/Error parsing type constraint near 'Bar:' in 'Bar:' at/;

is( Parse::Method::Signatures->new("ArrayRef")->tc(), "ArrayRef");
is( Parse::Method::Signatures->new("ArrayRef[Str => Str]")->tc(), "ArrayRef[Str => Str]");
is( Parse::Method::Signatures->new("ArrayRef[Str]")->tc(), "ArrayRef[Str]");
is( Parse::Method::Signatures->new("ArrayRef[0 => Foo]")->tc(), "ArrayRef[0 => Foo]");
is( Parse::Method::Signatures->new("ArrayRef[qq/0/]")->tc(), "ArrayRef[qq/0/]");
is( Parse::Method::Signatures->new("Foo|Bar")->tc(), "Foo|Bar");

lives_ok { Parse::Method::Signatures->new('$x')->param() };

throws_ok {
  Parse::Method::Signatures->new('$x[0]')->param()
  } qr/Error parsing parameter near '\$x' in '\$x\[0\]' at /,
  q{Error parsing parameter near '\$x' in '\$x\[0\]' at };


test_param(
  Parse::Method::Signatures->new('$x')->param(),
  { required => 1,
    sigil => '$',
    variable_name => '$x',
    __does => ["Parse::Method::Signatures::Param::Positional"],
  }
);

test_param(
  Parse::Method::Signatures->new('@x')->param(),
  { required => 1,
    sigil => '@',
    variable_name => '@x',
    __does => ["Parse::Method::Signatures::Param::Positional"],
  }
);

test_param(
  Parse::Method::Signatures->new(':$x')->param(),
  { required => 0,
    sigil => '$',
    variable_name => '$x',
    __does => ["Parse::Method::Signatures::Param::Named"],
  }
);

# ":y($x)" is an important test, as this tests the replacment of PPI's regexp operators
test_param(
  Parse::Method::Signatures->new(':y($x)')->param(),
  { required => 0,
    sigil => '$',
    variable_name => '$x',
    label => 'y',
    __does => ["Parse::Method::Signatures::Param::Named"],
  }
);

local $TODO = '?!';

test_param(
  Parse::Method::Signatures->new('$x?')->param(),
  { required => 0,
    sigil => '$',
    variable_name => '$x',
    __does => ["Parse::Method::Signatures::Param::Positional"],
  }
);


throws_ok {
  Parse::Method::Signatures->new(':foo( [$x, @y?])')->param(),
} qr/^Cannot have optional parameters in an unpacked-array near '\@y' in '\$x, \@y\?' at /,
  q/Cannot have optional parameters in an unpacked-array near '@y' in '$x, @y?' at /;
undef $TODO;

throws_ok {
  Parse::Method::Signatures->new(':foo( [$x, :@y])')->param(),
} qr/^Cannot have named parameters in an unpacked-array near ':' in '\$x, :\@y' at /,
  q/Cannot have named parameters in an unpacked-array near ':' in '$x, :@y' at /;
#test_param(
#  Parse::Method::Signatures->new(':foo( [$x, @y?])')->param(),
#  { required => 1,
#    sigil => '$',
#    variable_name => '$x',
#    label => 'y',
#    __does => ["Parse::Method::Signatures::Param::Named"],
#  }
#);

sub test_param {
  my ($param, $wanted, $msg) = @_;
  local $Test::Builder::Level = 2;

  use Data::Dump qw/pp/;
  if (my $isa = delete $wanted->{__isa}) {
    isa_ok($param, $isa, $msg)
      or diag(pp $param->meta->linearized_isa);
  }

  for ( @{ delete $wanted->{__does} || [] }) {
    ok(0 , "Param doesn't do $_" ) && last
      unless $param->does($_)
  }

  my $p = { %$param };
  delete $p->{_trait_namespace};
  eq_or_diff($p, $wanted, $msg);
}