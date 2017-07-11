use Test2::V0;
use Test::Alien;

alien_ok 'Alien::Foo';

my $obj = Alien::Foo->new;

alien_ok $obj;

done_testing;

package
  Alien::Foo;

sub new { bless {}, __PACKAGE__ }
sub cflags       {}
sub libs         {}
sub dynamic_libs {}
sub bin_dir      {}

