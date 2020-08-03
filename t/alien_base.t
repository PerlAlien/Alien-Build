use 5.008004;
use Test2::V0 -no_srand => 1;
use lib 'corpus/lib';
use Env qw( @PKG_CONFIG_PATH );
use File::Glob qw( bsd_glob );
use File::chdir;
use Path::Tiny qw( path );
use FFI::CheckLib;
use Text::ParseWords qw( shellwords );
use List::Util qw( first );

my $mock = mock 'FFI::CheckLib' => (
  override => [
    find_lib => sub {
      my %args = @_;
      my @libpath;
      if(ref $args{libpath})
      {
        @libpath = @{ $args{libpath} } if ref $args{libpath};
      }
      elsif(defined $args{libpath})
      {
        @libpath = ($args{libpath});
      }
      if(@libpath)
      {
        my @libs;
        foreach my $libpath (@libpath)
        {
          if($libpath eq '/roger/opt/libbumblebee/lib')
          {
            push @libs, '/roger/opt/libbumblebee/lib/libbumblebee.so';
            next;
          }
          next unless -d $libpath;
          local $CWD = $libpath;
          push @libs, map { path($_)->absolute->stringify } bsd_glob('*.so*');
        }
        return @libs;
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
  ok( Alien::libfoo1->atleast_version('1.2'), 'version atleast 1.2' );
  ok( !Alien::libfoo1->atleast_version('1.3'), 'version not atleast 1.3' );
  ok( Alien::libfoo1->exact_version('1.2.3'), 'version exactly 1.2.3' );
  ok( Alien::libfoo1->max_version('1.4'), 'version atmost 1.4' );

  subtest 'install type' => sub {
    is( Alien::libfoo1->install_type, 'system' );
    is( Alien::libfoo1->install_type('system'), T() );
    is( Alien::libfoo1->install_type('share'), F() );
  };

  is( Alien::libfoo1->config('name'), 'foo', 'config.name' );
  is( Alien::libfoo1->config('finished_installing'), T(), 'config.finished_installing' );

  is( [Alien::libfoo1->dynamic_libs], ['/usr/lib/libfoo.so','/usr/lib/libfoo.so.1'], 'dynamic_libs' );

  is( [Alien::libfoo1->dynamic_dir], [], 'dynamic_dir' );

  is( [Alien::libfoo1->bin_dir], [], 'bin_dir' );

  is( Alien::libfoo1->runtime_prop->{arbitrary}, 'one', 'runtime_prop' );

  {
    # no version
    my $mock = mock 'Alien::libfoo1' => (
      override => [
        version => sub { return undef },
      ],
    );

    ok( !eval{ Alien::libfoo1->atleast_version('1.2'); 1 } &&
        $@ =~ m/has no defined ->version/, 'no version atleast' );
    ok( !eval { Alien::libfoo1->exact_version('1.2.3'); 1 } &&
        $@ =~ m/has no defined ->version/, 'no version exactly' );
    ok( !eval { Alien::libfoo1->max_version('1.4'); 1 } &&
        $@ =~ m/has no defined ->version/, 'no version atmost' );
  }
};

subtest 'Alien::Build quazi system dylib' => sub {

  require Alien::libfoo1;

  my $mock = mock 'Alien::libfoo1' => (
    override => [
      libs => sub { return '-L/roger/opt/libbumblebee/lib -lbumblebee' },
    ],
  );

  is( Alien::libfoo1->libs, '-L/roger/opt/libbumblebee/lib -lbumblebee', 'libs' );
  is( [Alien::libfoo1->dynamic_libs], ['/roger/opt/libbumblebee/lib/libbumblebee.so'], 'dynamic_libs' );

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

  is(
    [Alien::libfoo2->dynamic_dir],
    array {
      item match qr /\bdynamic$/;
      end;
    },
    'dynamic_dir',
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
    foreach my $flag (keys %unix_flags)
    {
      is( [ Alien::Base->split_flags_unix( $flag ) ], $unix_flags{$flag} );
    }
  };

  subtest 'windows' => sub
  {
    foreach my $flag (keys %win_flags)
    {
      is( [ Alien::Base->split_flags_windows( $flag ) ], $win_flags{$flag} );
    }
  };

};

subtest 'ffi_name' => sub {

  require Alien::libfoo1;

  my @args_find_lib;

  my $mock1 = mock 'FFI::CheckLib' => (
    override => [
      find_lib => sub {
        @args_find_lib = @_;
        ('foo.dll','foo2.dll');
      },
    ],
  );

  is( [Alien::libfoo1->dynamic_libs], ['foo.dll','foo2.dll'], 'call dynamic_libs' );
  is( \@args_find_lib, [ lib => 'foo', libpath => [] ] );

  my $mock2 = mock 'Alien::Base' => (
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

subtest 'test an alt install' => sub {

  require Alien::libfoo1;
  require Alien::libfoo2;
  require Alien::libfoo3;

  subtest 'default' => sub {
    like( Alien::libfoo3->cflags,        qr{-I.*Alien-libfoo3/include -DFOO=1} );
    like( Alien::libfoo3->libs,          qr{-L.*Alien-libfoo3/lib -lfoo} );
    like( Alien::libfoo3->cflags_static, qr{-I.*Alien-libfoo3/include -DFOO=1 -DFOO_STATIC=1} );
    like( Alien::libfoo3->libs_static,   qr{-L.*Alien-libfoo3/lib -lfoo -lbar -lbaz} );
    is( Alien::libfoo3->version,         '2.3.4' );
    is( Alien::libfoo3->runtime_prop->{arbitrary}, 'two');
  };

  subtest 'foo1' => sub {

    my $alien = Alien::libfoo3->alt('foo1');

    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo3';

    like( $alien->cflags,        qr{-I.*Alien-libfoo3/include -DFOO=1} );
    like( $alien->libs,          qr{-L.*Alien-libfoo3/lib -lfoo} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo3/include -DFOO=1 -DFOO_STATIC=1} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo3/lib -lfoo -lbar -lbaz} );
    is( $alien->version,         '2.3.4' );
    is( $alien->runtime_prop->{arbitrary}, 'two');

  };

  subtest 'foo2' => sub {

    my $alien = Alien::libfoo3->alt('foo2');

    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo3';

    like( $alien->cflags,        qr{-I.*Alien-libfoo3/include -DFOO=2} );
    like( $alien->libs,          qr{-L.*Alien-libfoo3/lib -lfoo1} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo3/include -DFOO=2 -DFOO_STATIC=2} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo3/lib -lfoo1 -lbar -lbaz} );
    is( $alien->version,         '2.3.5' );
    is( $alien->runtime_prop->{arbitrary}, 'four');

  };

  subtest 'foo3' => sub {

    my $alien = Alien::libfoo3->alt('foo3');

    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo3';

    like( $alien->cflags,        qr{-I.*Alien-libfoo3/include -DFOO=1} );
    like( $alien->libs,          qr{-L.*Alien-libfoo3/lib -lfoo} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo3/include -DFOO=1 -DFOO_STATIC=1} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo3/lib -lfoo -lbar -lbaz} );
    is( $alien->version,         '2.3.4' );
    is( $alien->runtime_prop->{arbitrary}, 'five');

  };

  subtest 'foo4' => sub {

    eval { Alien::libfoo3->alt('foo4') };
    like $@, qr/no such alt: foo4/;

  };

  subtest 'default -> foo2 -> foo1' => sub {

    my $alien = Alien::libfoo3->alt('foo2')->alt('foo1');

    isa_ok $alien, 'Alien::Base';
    isa_ok $alien, 'Alien::libfoo3';

    like( $alien->cflags,        qr{-I.*Alien-libfoo3/include -DFOO=1} );
    like( $alien->libs,          qr{-L.*Alien-libfoo3/lib -lfoo} );
    like( $alien->cflags_static, qr{-I.*Alien-libfoo3/include -DFOO=1 -DFOO_STATIC=1} );
    like( $alien->libs_static,   qr{-L.*Alien-libfoo3/lib -lfoo -lbar -lbaz} );
    is( $alien->version,         '2.3.4' );
    is( $alien->runtime_prop->{arbitrary}, 'two');

  };

  subtest 'alt_names' => sub {

    is([Alien::libfoo1->alt_names], [], 'no alt means empty list of alt names');
    is([Alien::libfoo2->alt_names], [], 'no alt means empty list of alt names 2');
    is([Alien::libfoo3->alt_names], [qw( foo1 foo2 foo3 )], 'list of alt names');

  };

  subtest 'alt_exists' => sub {

    is(Alien::libfoo1->alt_exists('anything'), F(), 'class with no alts always retrusn false for alt_exists');
    is(Alien::libfoo1->alt_exists('foo1'), F(), 'class with no alts always retrusn false for alt_exists (2)');
    is(Alien::libfoo3->alt_exists('foo1'), T(), 'class with an alt returns true for alt_exists if it exists' );
    is(Alien::libfoo3->alt_exists('foo10'), F(), 'class with an alt returns false for alt_exists if it does not exists' );

  };

};

done_testing;
