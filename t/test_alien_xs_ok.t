use strict;
use warnings;
use Test::Alien::CanCompile;
use Test::Stream qw( -V1 -Tester Subtest );
use Test::Alien;

plan 3;

is(
  intercept { xs_ok '' },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'xs';
    };
    event Diag => sub {
      call message => '  XS does not have a module decleration that we could find';
    };
    end;
  },
  'xs with no module'
);

is(
  intercept { xs_ok "this should cause a compile error\nMODULE = Foo::Bar PACKAGE = Foo::Bar\n" },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'xs';
    };
    event Diag => sub {
      call message => '  ExtUtils::CBuilder->compile failed';
    };
  },
  'xs with C compile error'
);

my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 };

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = Foo::Bar PACKAGE = Foo::Bar

