use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;

{
  package Alien::Build::Plugin::Foo::Foo;
  use Alien::Build::Plugin;
  has arg => -1;
  sub init {
    my($self, $meta) = @_;
    push @{ $meta->prop->{test} }, $self->arg;
  };
}

subtest 'basic' => sub {

  alien_rc q{
    preload_plugin 'Foo::Foo', arg => 10;
    postload_plugin 'Foo::Foo', arg => 12;
  };

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Foo::Foo', arg => 11;
  };

  is(
    $build,
    object {
      call meta_prop => hash {
        field test => [ 10,11,12 ];
        etc;
      };
    },
    'loaded in correct order');

};

done_testing;
