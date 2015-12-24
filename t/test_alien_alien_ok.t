use strict;
use warnings;
use Test::Stream qw( -V1 -Tester );
use Test::Alien;

plan 3;

is(
  intercept { alien_ok 'Alien::Foo' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Alien::Foo responds to: dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper';
    };
    end;
  },
  "alien_ok with class"
);

is(
  intercept { alien_ok(Alien::Foo->new) },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Alien::Foo[instance] responds to: dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper';
    };
    end;
  },
  "alien_ok with instance"
);

is(
  intercept { alien_ok 'Alien::Bogus' },
  array {
    event Ok => sub {
      call pass => F();
      call name => 'Alien::Bogus responds to: dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper';
    };
    event Diag => sub {
      call message => "  missing method $_";
    } for qw( dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper );
    end;
  },
  "alien_ok with bad class",
);

package
  Alien::Foo;

sub new { bless {}, __PACKAGE__ }
sub dist_dir     {}
sub cflags       {}
sub libs         {}
sub install_type {}
sub config       {}
sub dynamic_libs {}
sub bin_dir      {}
sub alien_helper {}
