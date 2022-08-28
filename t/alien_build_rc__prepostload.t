use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Build;
use Test::Alien::Build;

subtest 'basic' => sub {

  alien_rc q{
    use strict;
    use warnings;

    print "package is @{[ __PACKAGE__ ]}\n";

    logx "hey";

    our $run_basic_pl;

    $run_basic_pl = 1;

    preload 'Foo::Bar';
    postload 'Baz::Frooble';

    1;
  };

  my $in_foobar;
  my $in_bazfrooble;

  my $foobar = mock 'Alien::Build::Plugin::Foo::Bar' => (
    override => [ init => sub { $in_foobar++ }],
  );

  my $frooble = mock 'Alien::Build::Plugin::Baz::Frooble' => (
    override => [ init => sub { $in_bazfrooble++ }],
  );

  my $build = alienfile_ok q{
    use alienfile;
  };

  is $in_foobar, 1;
  is $in_bazfrooble, 1;

};

done_testing;

package Alien::Build::Plugin::Foo::Bar;
use Alien::Build::Plugin;
package Alien::Build::Plugin::Baz::Frooble;
use Alien::Build::Plugin;

