use Test2::V0;
use Test::Alien;

plan 2;

alien_ok 'Alien::Foo';

my $obj = Alien::Foo->new;

alien_ok $obj;

package
  Alien::Foo;

sub new { bless {}, __PACKAGE__ }
sub cflags       {}
sub libs         {}
sub dynamic_libs {}
sub bin_dir      {}
