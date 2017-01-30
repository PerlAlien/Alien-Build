use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Alien::CanPlatypus;
use Test::Alien;

plan 8;

is(
  intercept { ffi_ok; },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'ffi';
    };
    end;
  },
  'empty ffi'
);

ffi_ok {}, 'min version test', with_subtest {
  my($ffi) = @_;
  plan 1;
  cmp_ok $ffi->VERSION, '>=', 0.12;
};

ffi_ok { ignore_not_found => 1 }, 'ignore not found', with_subtest {
  my($ffi) = @_;
  plan 3;
  cmp_ok $ffi->VERSION, '>=', 0.15;
  eval { $ffi->attach( foo => [] => 'void') };
  is $@, '';
  is __PACKAGE__->can('foo'), F();
};

ffi_ok { lang => 'Fortran' }, 'lang', with_subtest {
  my($ffi) = @_;
  plan 2;
  cmp_ok $ffi->VERSION, '>=', 0.18;
  is $ffi->lang, 'Fortran';
};

is(
  intercept { ffi_ok { symbols => [qw( bogus1 bogus2 )] } },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'ffi';
    };
    event Diag => sub {};
    event Diag => sub {
      call message => '  bogus1 not found';
    };
    event Diag => sub {
      call message => '  bogus2 not found';
    };
    end;
  },
  'not found error'
);
