use Test2::V0;
use Test::Alien;
use File::Temp qw( tempdir );
use File::Spec;

is(
  synthetic(),
  object {
    prop blessed => 'Test::Alien::Synthetic';
    prop reftype => 'HASH';
    call cflags  => '';
    call libs    => '';
    call sub { [shift->dynamic_libs] }  => [];
    call sub { [shift->bin_dir] }       => [];
  },
  'empty synthetic alien',
);

is(
  synthetic({ cflags => '-DFOO=1 -I/foo/bar/baz'}),
  object {
    prop blessed       => 'Test::Alien::Synthetic';
    call cflags        => '-DFOO=1 -I/foo/bar/baz';
    call cflags_static => '-DFOO=1 -I/foo/bar/baz';
  },
  'cflags',
);

is(
  synthetic({ libs => '-L/foo/bar/baz -lfoo'}),
  object {
    prop blessed     => 'Test::Alien::Synthetic';
    call libs        => '-L/foo/bar/baz -lfoo';
    call libs_static => '-L/foo/bar/baz -lfoo';
  },
  'libs',
);

is(
  synthetic({ dynamic_libs => [qw( foo bar baz )] }),
  object {
    prop blessed => 'Test::Alien::Synthetic';
    call sub { [shift->dynamic_libs] } => [qw( foo bar baz )];
  },
  'dynamic_libs',
);

my $dir = tempdir( CLEANUP => 1 );

is(
  synthetic({ bin_dir => $dir }),
  object {
    prop blessed => 'Test::Alien::Synthetic';
    call bin_dir => $dir;
  },
  'bin_dir (exists)',
);

is(
  synthetic({ bin_dir => File::Spec->catdir($dir, 'foo') }),
  object {
    prop blessed => 'Test::Alien::Synthetic';
    call sub { [shift->bin_dir] } => [];
  },
  'bin_dir (does not exist)',
);

is(
  synthetic({ cflags => '-DCFLAGS=1', cflags_static => '-DCFLAGS_STATIC=1', libs => '-L/lib -lfoo', libs_static => '-L/lib -lfoo -lbar -lbaz' }),
  object {
    prop blessed       => 'Test::Alien::Synthetic';
    call cflags        => '-DCFLAGS=1';
    call cflags_static => '-DCFLAGS_STATIC=1';
    call libs          => '-L/lib -lfoo';
    call libs_static   => '-L/lib -lfoo -lbar -lbaz';
  },
  'static flags',
);

done_testing;
