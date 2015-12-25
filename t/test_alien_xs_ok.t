use strict;
use warnings;
use Test::Alien::CanCompile;
use Test::Stream qw( -V1 -Tester Subtest );
use Test::Alien;

plan 5;

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
  intercept { xs_ok '', sub { } },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'xs';
    };
    event Diag => sub {
      call message => '  XS does not have a module decleration that we could find';
    };
    event Subtest => sub {
      call buffered  => T();
      call subevents => array {
        event Plan => sub {
          call max       => 0;
          call directive => 'SKIP';
          call reason    => 'subtest requires xs success';
        };
        end;
      };
    };
    end;
  },
  'xs fail with subtest'
);

# TODO: test that parsexs error should fail

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

# TODO: test that link error should fail

my $xs = do { local $/; <DATA> };
xs_ok { xs => $xs, verbose => 1 }, sub {
  plan 1;
  is Foo::Bar::baz(), 42, 'call Foo::Bar::baz()';
};

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

int baz()
{
  return 42;
}

MODULE = Foo::Bar PACKAGE = Foo::Bar

int baz();
  
