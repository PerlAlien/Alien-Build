use Test2::V0;
use Alien::Build::Plugin::Gather::IsolateDynamic;
use lib 't/lib';
use MyTest;
use Capture::Tiny qw( capture_merged );

subtest 'basic' => sub {

  my $check = sub {
    my($build) = @_;
  
    note scalar capture_merged {
      $build->probe;
      $build->download;
      $build->build;
    };
  
   my $stage = $build->install_prop->{stage};
 
    ok(-f "$stage/lib/$_", "correct: lib/$_") for qw( libfoo.a );
    ok(-f "$stage/bin/$_", "correct: bin/$_") for qw( foo foo.exe );

    foreach my $file (qw( libfoo.dylib libfoo.bundle libfoo.la foo.dll.a ))
    {
      ok(!-f "$stage/lib/$file",    "moved:   lib/$file");
      ok(-f "$stage/dynamic/$file", "correct: dynamic/$file");
    }
  };

  subtest 'less indirect' => sub {

    my $build = alienfile q{
      use alienfile;
      use Path::Tiny qw( path );

      probe sub { 'share' };

      share {
        download sub { path('foo-1.00.tar.gz')->touch };
        extract  sub { path($_)->touch for qw( file1 file2 ) };

        build sub {
      
          my($build) = @_;
          print "in build\n";
          
          my $dir = path($build->install_prop->{stage});
          $dir->child('lib')->mkpath;
          $dir->child('lib', $_)->touch for qw( libfoo.a libfoo.dylib libfoo.bundle libfoo.la foo.dll.a );
          $dir->child('bin')->mkpath;
          $dir->child('bin', $_)->touch for qw( foo foo.exe foo.dll );
      
        };

        plugin 'Gather::IsolateDynamic';
      };

    };
    
    $check->($build);

  };

  subtest 'destdir' => sub {

    my $build = alienfile q{
      use alienfile;
      use Path::Tiny qw( path );
      use Alien::Build::Util qw( _destdir_prefix );

      probe sub { 'share' };

      meta_prop->{destdir} = 1;

      share {

        download sub { path('foo-1.00.tar.gz')->touch };
        extract  sub { path($_)->touch for qw( file1 file2 ) };

        build sub {
      
          my($build) = @_;
          print "in build\n";
          my $dir = path(_destdir_prefix($ENV{DESTDIR}, $build->install_prop->{prefix}));
          $dir->child('lib')->mkpath;
          $dir->child('lib', $_)->touch for qw( libfoo.a libfoo.dylib libfoo.bundle libfoo.la foo.dll.a );
          $dir->child('bin')->mkpath;
          $dir->child('bin', $_)->touch for qw( foo foo.exe foo.dll );
      
        };
      
        plugin 'Gather::IsolateDynamic';
      };
    };
  
    $check->($build);
  };
  
};

done_testing;
