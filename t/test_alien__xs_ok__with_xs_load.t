use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test2::Mock;

my $xs = do { local $/; <DATA> };

my @aliens = (
  synthetic({ cflags => '-DFOO_ONE=42' }),
  synthetic({ cflags => '-DFOO_TWO=47' }),
);

alien_ok $aliens[0];
alien_ok $aliens[1];

my @xs_load_args;

my $mock = Test2::Mock->new(
  class => 'Test::Alien::Synthetic',
  add => [
    xs_load => sub {
      my($alien, $module, $version, @rest) = @_;
      @xs_load_args = @_;
      require XSLoader;
      XSLoader::load($module, $version);
    },
  ],
);

xs_ok { xs => $xs, verbose => 1 }, with_subtest {
  my($mod) = @_;
  is($mod->get_foo_one, 42, 'get_foo_one');
  is($mod->get_foo_two, 47, 'get_foo_two');
};

is(
  \@xs_load_args,
  array {
    item object {
      call 'cflags' => '-DFOO_ONE=42';
    };
    item match(qr{^Test::Alien::XS::Mod});
    item '0.01';
    item object {
      call 'cflags' => '-DFOO_TWO=47';
    };
    end;
  },
  'called xs_load with correct args',
);

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = TA_MODULE PACKAGE = TA_MODULE

int
get_foo_one(klass)
    const char *klass
  CODE:
    RETVAL = FOO_ONE;
  OUTPUT:
    RETVAL

int
get_foo_two(klass)
    const char *klass
  CODE:
    RETVAL = FOO_TWO;
  OUTPUT:
    RETVAL
