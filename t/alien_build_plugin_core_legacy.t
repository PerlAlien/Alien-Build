use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Legacy;
use lib 't/lib';
use MyTest;
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );

subtest 'basic' => sub {

  my $build = alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    probe sub { 'share' };
    share {
      download sub { path('foo-1.00.tar.gz')->touch };
      extract  sub { path($_)->touch for qw( file1 file 2 ) };
      build sub {};
      gather sub {
        my($build) = @_;
        $build->runtime_prop->{cflags}  = '-DFOO=1';
        $build->runtime_prop->{libs}    = '-lfoo';
        $build->runtime_prop->{version} = '1.2.3';
      };
    };
  };
  
  capture_merged {
    $build->probe;
    $build->download;
    $build->build;
  };
  
  is( $build->runtime_prop->{cflags},        '-DFOO=1', 'cflags'        );
  is( $build->runtime_prop->{libs},          '-lfoo',   'libs'          );
  is( $build->runtime_prop->{cflags_static}, '-DFOO=1', 'cflags_static' );
  is( $build->runtime_prop->{libs_static},   '-lfoo',   'libs_static'   );
  
  is(
    $build->runtime_prop->{legacy},
    hash {
      field 'finished_installing' => T();
      field 'install_type'        => 'share';
      field 'version'             => '1.2.3';
      field 'original_prefix'     => $build->runtime_prop->{prefix};
    },
    'legacy hash',
  );

};

done_testing;
