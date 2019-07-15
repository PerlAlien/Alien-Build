use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Probe::CBuilder;
use Capture::Tiny qw( capture_merged );

skip_all 'CI only' unless $ENV{USER} eq 'cip' && $ENV{GROUP} eq 'cip';

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

};

done_testing;

