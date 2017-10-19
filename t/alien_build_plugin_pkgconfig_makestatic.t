use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::MakeStatic;
use Capture::Tiny qw( capture_merged );

skip_all 'test requires PkgConfig.pm'
  unless eval { require PkgConfig; PkgConfig->VERSION(0.14026) };

subtest 'recursive' => sub {

  my $build = alienfile q{
    use alienfile;
    use Path::Tiny qw( path );

    plugin 'PkgConfig::MakeStatic';

    probe sub { 'share' };
    plugin 'PkgConfig::PP' => 'foo1';

    share {

      download sub { path('file1')->touch };
      extract sub  { path('file2')->touch };
      build sub {
        my($build) = @_;
        my $dir = path($build->install_prop->{prefix}, 'lib', 'pkgconfig');
        $dir->mkpath;
        path($dir, 'foo1.pc')->spew(
          "libdir=/foo/bar\n" .
          "Cflags: -I/baz/include\n" .
          "Cflags.private: -DUSE_STATIC=1\n" .
          "Libs: -L\${libdir} -lxml2\n" .
          "Libs.private:  -lpthread -lz   -liconv -lm\n"
        );
        path($dir, 'bar1.pc')->spew(
          "libdir=/foo/bar\n" .
          "Libs: -L\${libdir} -lfoo2\n" .
          "Libs.private:  -lbar -lbaz\n"
        );
      };

    };
  };

  note capture_merged {
    $build->download;
    $build->build;
    ();
  };

  like $build->runtime_prop->{libs}, qr{-L/foo/bar -lxml2 -lpthread -lz -liconv -lm};

};

done_testing;
