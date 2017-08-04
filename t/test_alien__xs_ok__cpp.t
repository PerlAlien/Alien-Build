use Test2::V0 -no_srand => 1;
use Test::Alien;
use Test::Alien::CanCompileCpp;
use lib 't/lib';
use Test2::Require::Dev;

skip_all 'skipping on production releases (for now)'
  if defined $Test::Alien::VERSION && $Test::Alien::VERSION =~ /\.[0-9]{2}$/;

my $xs = do { local $/; <DATA> };

my $subtest = sub {
  my($module) = @_;
  is($module->get_value(), 42);
};

xs_ok {
  xs      => $xs,
  cpp     => 1,
  verbose => 1,
}, 'by setting cpp => 1', with_subtest { $subtest->(@_) };

xs_ok {
  xs      => $xs,
  'C++'   => 1,
  verbose => 1,
}, 'by setting C++ => 1', with_subtest { $subtest->(@_) };

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

class Foo {
public:
  static int get_a_value();
};

int Foo::get_a_value()
{
  return 42;
}

MODULE = TA_MODULE PACKAGE = TA_MODULE

int get_value(klass);
    const char *klass
  CODE:
    RETVAL = Foo::get_a_value();
  OUTPUT:
    RETVAL
  
