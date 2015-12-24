use strict;
use warnings;
use Test::Stream qw( -V1 -Tester );
use Test::Alien;

plan 3;

is(
  intercept { load_alien 'Alien::Foo' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Alien::Foo responds to: dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper';
    };
    end;
  },
  "load_alien with class"
);

is(
  intercept { load_alien(Alien::Foo->new) },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Alien::Foo[instance] responds to: dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper';
    };
    end;
  },
  "load_alien with instance"
);

is(
  intercept { load_alien 'Alien::Bogus' },
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
  "load_alien with bad class",
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
