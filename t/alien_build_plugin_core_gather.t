use Test2::V0 -no_srand => 1;
use utf8;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Gather;
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _dump _destdir_prefix );
use Path::Tiny qw( path );
use File::Temp qw( tempdir );

subtest 'destdir filter' => sub {

  my $build = alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    meta_prop->{destdir} = 1;
    meta_prop->{destdir_filter} = qr/^(bin|lib)\/.*$/;
    probe sub { 'share' };
    share {
      download sub { path('foo-1.00.tar.gz')->touch };
      extract  sub { path($_)->touch for qw( file1 file2 ) };
      build sub {
        my($build) = @_;
        my $prefix = $build->install_prop->{prefix};
        $prefix =~ s{^([a-z]):}{$1}i if $^O eq 'MSWin32';
        my $destdir_prefix = path(Alien::Build::Util::_destdir_prefix($ENV{DESTDIR}, $prefix));
        $destdir_prefix->child($_)->mkpath for qw( bin lib etc );
        $destdir_prefix->child('bin/foo.exe')->touch;
        $destdir_prefix->child('lib/libfoo.a')->touch;
        $destdir_prefix->child('etc/foorc')->touch;
      };
    };
  };

  note capture_merged {
    eval {
      $build->probe;
      $build->download;
      $build->build;
    };
    warn $@ if $@;
    ();
  };

  note _dump $build->install_prop;

  my $stage = path($build->install_prop->{stage});

  ok( -f $stage->child('bin/foo.exe'), 'bin/foo.exe' );
  ok( -f $stage->child('lib/libfoo.a'), 'lib/libfoo.a' );
  ok( !-f $stage->child('etc/foorc'), 'etc/foorc' );

};

subtest 'patch' => sub {

  my $build = alienfile q{
    use alienfile;
    use Path::Tiny qw( path );
    probe sub { 'share' };
    share {
      download sub { path('foo-1.00.tar.gz')->touch };
      extract  sub { path($_)->touch for qw( file1 file2 ) };
      build sub {
        my($build) = @_;
        my $prefix = path($build->install_prop->{prefix});
        print "prefix = $prefix\n";
        $prefix->mkpath;
        $prefix->child('foo.txt')->touch;
      };
    };
  };

  my $patch = path($build->install_prop->{patch} = tempdir( CLEANUP => 1 ));
  $patch->child('foo.diff')->touch;
  my $stage = path($build->install_prop->{stage});

  my $error = $@;
  note capture_merged {
    eval {
      $build->probe;
      $build->download;
      $build->build;
    };
    my $error = $@;
    warn $error if $error;
    ();
  };

  is $error, '';

  note _dump $build->install_prop;

  ok( -f $stage->child('_alien/patch/foo.diff') );
};

subtest 'pkg-config path during gather' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    use Path::Tiny qw( path );
    use Env qw( @PKG_CONFIG_PATH );
    probe sub { 'share' };
    share {
      download sub { path('file1')->touch };
      extract  sub { path('file2')->touch };
      build    sub {
        my($build) = @_;
        my $prefix = path($build->install_prop->{prefix});
        $build->log("prefix = $prefix");
        $prefix->child('lib/pkgconfig')->mkpath;
        $prefix->child('lib/pkgconfig/x3.pc')->spew("Name: x3\n");
        $prefix->child('share/pkgconfig')->mkpath;
        $prefix->child('share/pkgconfig/x4.pc')->spew("Name: x4\n");
      };
      gather   sub {
        my($build) = @_;
        $build->install_prop->{my_pkg_config_path} = [@PKG_CONFIG_PATH];
      };
    };
  };

  alien_build_ok;

  is(
    $build->install_prop,
    hash {
      field my_pkg_config_path => array {
        item validator(sub {
          return -f "$_/x3.pc";
        });
        item validator(sub {
          return -f "$_/x4.pc";
        });
        end;
      };
      etc;
    },
    'has arch and arch-indy pkg-config paths',
  );


};

subtest '_alien/alien.json should be okay with unicode' => sub {

  my $build = alienfile q{
    use alienfile;
    use utf8;
    probe sub { 'system' };
    gather sub {
      my($build) = @_;
      $build->runtime_prop->{'龍'} = '火';
    };
  };

  alien_build_ok;
  is(
    $build->runtime_prop,
    hash {
      field '龍' => '火';
      etc;
    }
  );

  my $json_file = path($build->install_prop->{prefix}, '_alien', 'alien.json');
  ok -r $json_file;

  require JSON::PP;
  my $config = JSON::PP::decode_json($json_file->slurp);
  is(
    $config,
    hash {
      field '龍' => '火';
      etc;
    }
  );


};

done_testing;
