use Test2::V0;
use Test::Alien;
use Env qw( @PATH );

plan 4;

is(
  intercept { alien_ok 'Alien::Foo' },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Alien::Foo responds to: cflags libs dynamic_libs bin_dir';
    };
    end;
  },
  "alien_ok with class"
);

is $PATH[0], '/foo/bar/baz', 'bin_dir added to path';

is(
  intercept { alien_ok(Alien::Foo->new) },
  array {
    event Ok => sub {
      call pass => T();
      call name => 'Alien::Foo[instance] responds to: cflags libs dynamic_libs bin_dir';
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
      call name => 'Alien::Bogus responds to: cflags libs dynamic_libs bin_dir';
    };
    event Diag => sub {};
    event Diag => sub {
      call message => "  missing method $_";
    } for qw( cflags libs dynamic_libs bin_dir );
    end;
  },
  "alien_ok with bad class",
);

package
  Alien::Foo;

sub new { bless {}, __PACKAGE__ }
sub cflags       {}
sub libs         {}
sub dynamic_libs {}
sub bin_dir      { '/foo/bar/baz' }
