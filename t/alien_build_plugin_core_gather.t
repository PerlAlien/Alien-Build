use Test2::Bundle::Extended;
use Alien::Build::Plugin::Core::Gather;
use lib 't/lib';
use MyTest;
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _dump _destdir_prefix );
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

done_testing;
