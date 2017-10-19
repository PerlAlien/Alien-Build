use Test2::V0 -no_srand => 1;
use Test2::Mock;
use lib 'corpus/lib';
use Env qw( @PKG_CONFIG_PATH );
use File::Glob qw( bsd_glob );
use File::chdir;
use Path::Tiny qw( path );
use FFI::CheckLib;
use Text::ParseWords qw( shellwords );
use List::Util qw( first );

my $mock = Test2::Mock->new(
  class => 'FFI::CheckLib',
  override => [
    find_lib => sub {
      my %args = @_;
      if($args{libpath})
      {
        return unless -d $args{libpath};
        return sort do {
          local $CWD = $args{libpath};
          map { path($_)->absolute->stringify } bsd_glob('*.so*');
        };
      }
      else
      {
        if($args{lib} eq 'foo')
        {
          return ('/usr/lib/libfoo.so', '/usr/lib/libfoo.so.1');
        }
        else
        {
          return;
        }
      }
    },
  ],
);


unshift @PKG_CONFIG_PATH, path('corpus/pkgconfig')->absolute->stringify;

subtest 'AB::MB sys install' => sub {

  require Alien::Foo1;

  my $cflags  = Alien::Foo1->cflags;
  my $libs    = Alien::Foo1->libs;
  my $version = Alien::Foo1->version;

  $libs =~ s{^\s+}{};

  is $cflags, '-DFOO=stuff', "cflags: $cflags";
  is $libs,   '-lfoo1', "libs: $libs";
  is $version, '3.99999', "version: $version";
};

subtest 'AB::MB share install' => sub {

  require Alien::Base::PkgConfig;

  require Alien::Foo2;

  my $cflags  = Alien::Foo2->cflags;
  my $libs    = Alien::Foo2->libs;
  my $version = Alien::Foo2->version;

  ok $cflags,  "cflags: $cflags";
  ok $libs,    "libs:   $libs";
  is $version, '3.2.1', "version: $version";

  (first { /^-I/ } shellwords($cflags)) =~ /^-I(.*)$/;
  ok defined $1 && -f "$1/foo2.h", "include path";
  note "include path: $1";

  (first { /^-L/ } shellwords($libs)) =~ /^-L(.*)$/;
  ok defined $1 && -f "$1/libfoo2.a", "lib path";
  note "lib path: $1";

};

subtest 'Alien::Build system' => sub {

  require Alien::libfoo1;

  is( -f path(Alien::libfoo1->dist_dir)->child('_alien/for_libfoo1'), T(), 'dist_dir');
  is( Alien::libfoo1->cflags, '-DFOO=1', 'cflags' );
  is( Alien::libfoo1->cflags_static, '-DFOO=1 -DFOO_STATIC=1', 'cflags_static');
  is( Alien::libfoo1->libs, '-lfoo', 'libs' );
  is( Alien::libfoo1->libs_static, '-lfoo -lbar -lbaz', 'libs_static' );
  is( Alien::libfoo1->version, '1.2.3', 'version');

  subtest 'install type' => sub {
    is( Alien::libfoo1->install_type, 'system' );
    is( Alien::libfoo1->install_type('system'), T() );
    is( Alien::libfoo1->install_type('share'), F() );
  };

  is( Alien::libfoo1->config('name'), 'foo', 'config.name' );
  is( Alien::libfoo1->config('finished_installing'), T(), 'config.finished_installing' );

  is( [Alien::libfoo1->dynamic_libs], ['/usr/lib/libfoo.so','/usr/lib/libfoo.so.1'], 'dynamic_libs' );

  is( [Alien::libfoo1->bin_dir], [], 'bin_dir' );

  is( Alien::libfoo1->runtime_prop->{arbitrary}, 'one', 'runtime_prop' );
};

subtest 'Alien::Build share' => sub {

  require Alien::libfoo2;

  is( -f path(Alien::libfoo2->dist_dir)->child('_alien/for_libfoo2'), T(), 'dist_dir');

  subtest 'cflags' => sub {
    is(
      [shellwords(Alien::libfoo2->cflags)],
      array {
        item match qr/^-I.*include/;
        item '-DFOO=1';
        end;
      },
      'cflags',
    );

    my($dir) = [shellwords(Alien::libfoo2->cflags)]->[0] =~ /^-I(.*)$/;

    is(
      -f path($dir)->child('foo.h'),
      T(),
      '-I directory points to foo.h location',
    );

    is(
      [shellwords(Alien::libfoo2->cflags_static)],
      array {
        item match qr/^-I.*include/;
        item '-DFOO=1';
        item '-DFOO_STATIC=1';
        end;
      },
      'cflags_static',
    );

    ($dir) = [shellwords(Alien::libfoo2->cflags_static)]->[0] =~ /^-I(.*)$/;

    is(
      -f path($dir)->child('foo.h'),
      T(),
      '-I directory points to foo.h location (static)',
    );
  };

  subtest 'libs' => sub {

    is(
      [shellwords(Alien::libfoo2->libs)],
      array {
        item match qr/-L.*lib/;
        item '-lfoo';
        end;
      },
      'libs',
    );

    my($dir) = [shellwords(Alien::libfoo2->libs)]->[0] =~ /^-L(.*)$/;

    is(
      -f path($dir)->child('libfoo.a'),
      T(),
      '-L directory points to libfoo.a location',
    );


    is(
      [shellwords(Alien::libfoo2->libs_static)],
      array {
        item match qr/-L.*lib/;
        item '-lfoo';
        item '-lbar';
        item '-lbaz';
        end;
      },
      'libs_static',
    );

    ($dir) = [shellwords(Alien::libfoo2->libs_static)]->[0] =~ /^-L(.*)$/;

    is(
      -f path($dir)->child('libfoo.a'),
      T(),
      '-L directory points to libfoo.a location (static)',
    );

  };

  is( Alien::libfoo2->version, '2.3.4', 'version' );

  subtest 'install type' => sub {
    is( Alien::libfoo2->install_type, 'share' );
    is( Alien::libfoo2->install_type('system'), F() );
    is( Alien::libfoo2->install_type('share'), T() );
  };

  is( Alien::libfoo2->config('name'), 'foo', 'config.name' );
  is( Alien::libfoo2->config('finished_installing'), T(), 'config.finished_installing' );

  is(
    [Alien::libfoo2->dynamic_libs],
    array {
      item match qr/libfoo.so$/;
      item match qr/libfoo.so.2$/;
      end;
    },
    'dynamic_libs',
  );

  is(
    [Alien::libfoo2->bin_dir],
    array {
      item T();
      end;
    },
    'bin_dir',
  );

  is( -f path(Alien::libfoo2->bin_dir)->child('foo-config'), T(), 'has a foo-config');

  is( Alien::libfoo2->runtime_prop->{arbitrary}, 'two', 'runtime_prop' );

};

subtest 'build flags' => sub {

  my %unix_flags = (
    q{ -L/a/b/c -lz -L/a/b/c } => [ "-L/a/b/c", "-lz", "-L/a/b/c" ],
  );

  my %win_flags = (
    q{ -L/a/b/c -lz -L/a/b/c } => [ "-L/a/b/c", "-lz", "-L/a/b/c" ],
    q{ -LC:/a/b/c -lz -L"C:/a/b c/d" } => [ "-LC:/a/b/c", "-lz", "-LC:/a/b c/d" ],
    q{ -LC:\a\b\c -lz } => [ q{-LC:\a\b\c}, "-lz" ],
  );

  subtest 'unix' => sub {
    while ( my ($flag, $split) = each %unix_flags ) {
      is( [ Alien::Base->split_flags_unix( $flag ) ], $split );
    }
  };

  subtest 'windows' => sub {
    while ( my ($flag, $split) = each %win_flags ) {
      is( [ Alien::Base->split_flags_windows( $flag ) ], $split );
    }
  };

};

subtest 'ffi_name' => sub {

  require Alien::libfoo1;

  my @args_find_lib;

  my $mock1 = Test2::Mock->new(
    'class' => 'FFI::CheckLib',
    override => [
      find_lib => sub {
        @args_find_lib = @_;
        ('foo.dll','foo2.dll');
      },
    ],
  );

  is( [Alien::libfoo1->dynamic_libs], ['foo.dll','foo2.dll'], 'call dynamic_libs' );
  is( \@args_find_lib, [ lib => 'foo' ] );

  my $mock2 = Test2::Mock->new(
    class => 'Alien::Base',
    around => [
      runtime_prop => sub {
        my($orig, @args) = @_;
        my $prop = $orig->(@args);
        { ffi_name => 'roger', %$prop };
      },
    ],
  );

  is( [Alien::libfoo1->dynamic_libs], ['foo.dll','foo2.dll'], 'call dynamic_libs' );
  is( \@args_find_lib, [ lib => 'roger' ] );

};

done_testing;
