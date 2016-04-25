use strict;
use warnings;
use Test2::Bundle::Extended;
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
