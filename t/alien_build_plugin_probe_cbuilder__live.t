use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Probe::CBuilder;
use Capture::Tiny qw( capture_merged );

skip_all 'CI only' unless defined $ENV{CIPSOMETHING} && $ENV{CIPSOMETHING} eq 'true';

subtest 'live test' => sub {

  require ExtUtils::CBuilder;

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'Probe::CBuilder' => (
      cflags => '-I/usr/local/include ',
      libs   => '-L/usr/local/lib ',
    );
  };

  alien_build_ok;
  alien_install_type_is 'system';

  is(
    $build->runtime_prop,
    hash {
      field cflags  => '-I/usr/local/include ';
      field libs    => '-L/usr/local/lib ';
      etc;
    },
  );

};


alien_subtest 'multiple probes' => sub {

  require ExtUtils::CBuilder;

  my $build = alienfile_ok q{
    use alienfile;

    plugin 'Probe::CBuilder' => (
      cflags => '-I/usr/local/include ',
      libs   => '-L/usr/local/lib ',
    );

    probe sub { 'system' };

    my $count = 0;
    meta->around_hook(probe => sub {
      my $orig  = shift;
      my $build = shift;
      my $type = $orig->($build, @_);
      if($count++ == 0)
      {
        Test2::V0::note("first convert $type to share");
        return 'share';
      }
      else
      {
        Test2::V0::note("finally return $type");
        return $type;
      }
    });

  };

  alien_install_type_is 'system';
  alien_build_ok;

  is(
    $build->runtime_prop,
    hash {
      field cflags  => DNE();
      field libs    => DNE();
      etc;
    },
  );

};


done_testing;

