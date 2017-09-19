package Alien::Foo;

sub new { bless {}, __PACKAGE__ }
sub cflags       {}
sub libs         {}
sub dynamic_libs {}
sub bin_dir      { '/foo/bar/baz' }

1;
