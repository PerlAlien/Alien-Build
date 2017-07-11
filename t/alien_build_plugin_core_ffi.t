use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::FFI;
use Capture::Tiny qw( capture_merged );

subtest basic => sub {

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
        $dir->child('lib', 'libfoo.a')->touch;
      };

      ffi { 

        patch sub { shift->{runtime_prop}->{my_did_patch_ffi} = 1 };
      
        build sub {
          my($build) = @_;
          print "in build_ffi DESTDIR = $ENV{DESTDIR}\n";
          my $dir = path(_destdir_prefix($ENV{DESTDIR}, $build->install_prop->{prefix}));
          $dir->child('dynamic')->mkpath;
          $dir->child('dynamic', 'libfoo.so')->touch;
          $dir->child('lib')->mkpath;
          $dir->child('lib', 'libgarbage.a')->touch;
          $build->{runtime_prop}->{my_did_build_ffi} = 1;
        };
      
        gather sub {
          my($build) = @_;
          print "in gather_ffi\n";
          $build->{runtime_prop}->{my_did_gather_ffi} = 1;
        };
      };
    
    };
  };

  note scalar capture_merged {
    $build->probe;
    $build->download;
    $build->build;
  };

  ok($build->{runtime_prop}->{my_did_patch_ffi},  'did patch_ffi');
  ok($build->{runtime_prop}->{my_did_build_ffi},  'did build_ffi');
  ok($build->{runtime_prop}->{my_did_gather_ffi}, 'did gather_ffi');

  my $stage = $build->install_prop->{stage};
  
  ok(-f "$stage/lib/libfoo.a", 'has static lib');
  ok(-f "$stage/dynamic/libfoo.so", 'has dynamic lib');
  ok(!-f "$stage/lib/libgarbage.a", "filter out garbage");
  
};

subtest deprecated => sub {

  my($out, $build) = capture_merged { alienfile q{
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
        $dir->child('lib', 'libfoo.a')->touch;
      };

      patch_ffi sub { shift->{runtime_prop}->{my_did_patch_ffi} = 1 };
      
      build_ffi sub {
        my($build) = @_;
        print "in build_ffi DESTDIR = $ENV{DESTDIR}\n";
        my $dir = path(_destdir_prefix($ENV{DESTDIR}, $build->install_prop->{prefix}));
        $dir->child('dynamic')->mkpath;
        $dir->child('dynamic', 'libfoo.so')->touch;
        $dir->child('lib')->mkpath;
        $dir->child('lib', 'libgarbage.a')->touch;
        $build->{runtime_prop}->{my_did_build_ffi} = 1;
      };
      
      gather_ffi sub {
        my($build) = @_;
        print "in gather_ffi\n";
        $build->{runtime_prop}->{my_did_gather_ffi} = 1;
      };
    
    };
  } };
  
  note "build warnings: $out";

  note scalar capture_merged {
    $build->probe;
    $build->download;
    $build->build;
  };

  ok($build->{runtime_prop}->{my_did_patch_ffi},  'did patch_ffi');
  ok($build->{runtime_prop}->{my_did_build_ffi},  'did build_ffi');
  ok($build->{runtime_prop}->{my_did_gather_ffi}, 'did gather_ffi');

  my $stage = $build->install_prop->{stage};
  
  ok(-f "$stage/lib/libfoo.a", 'has static lib');
  ok(-f "$stage/dynamic/libfoo.so", 'has dynamic lib');
  ok(!-f "$stage/lib/libgarbage.a", "filter out garbage");
  
};

done_testing;
