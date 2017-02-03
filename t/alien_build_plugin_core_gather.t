use Test2::Bundle::Extended;
use Alien::Build::Plugin::Core::Gather;
use lib 't/lib';
use MyTest;
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _dump );
use Path::Tiny qw( path );

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
        my $prefix = path($ENV{DESTDIR})->child($build->install_prop->{prefix});
        $prefix->child($_)->mkpath for qw( bin lib etc );
        $prefix->child('bin/foo.exe')->touch;
        $prefix->child('lib/libfoo.a')->touch;
        $prefix->child('etc/foorc')->touch;
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

done_testing;
