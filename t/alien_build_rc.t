use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Build;
use Test::Alien::Build;

subtest 'basic' => sub {

  local $ENV{ALIEN_BUILD_RC} = 'corpus/rc/basic.pl';

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

subtest 'preload code ref' => sub {

  my $meta1;
  my $meta2;

  local @Alien::Build::rc::PRELOAD = (sub {
    ($meta1) = @_;
  });

  local @Alien::Build::rc::POSTLOAD = (sub {
    ($meta2) = @_;
  });

  my $build = alienfile_ok q{
    use alienfile;
  };

  isa_ok $meta1, 'Alien::Build::Meta';
  isa_ok $meta2, 'Alien::Build::Meta';

};

done_testing;

package Alien::Build::Plugin::Foo::Bar;
use Alien::Build::Plugin;
package Alien::Build::Plugin::Baz::Frooble;
use Alien::Build::Plugin;

