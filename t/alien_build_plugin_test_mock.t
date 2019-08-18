use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Test::Mock;
use Path::Tiny qw( path );

subtest 'basic' => sub {
  alienfile_ok q{
    use alienfile;
    plugin 'Test::Mock';
  };
};

subtest 'probe' => sub {

  subtest 'share' => sub {

    alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        'probe' => 'share'
      );
    };

    alien_install_type_is 'share';

  };

  subtest 'share' => sub {

    alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        'probe' => 'system'
      );
    };

    alien_install_type_is 'system';

  };

  subtest 'share' => sub {

    alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        'probe' => 'die'
      );
    };

    alien_install_type_is 'share';

  };

};

subtest 'download' => sub {

  subtest 'default' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        probe => 'share',
        download => 1,
      );
    };
    alien_download_ok;
    my $tarball = path($build->install_prop->{download});
    is(
      $tarball,
      object {
        call basename => 'foo-1.00.tar.gz';
        call slurp => path('corpus/dist/foo-1.00.tar.gz')->slurp;
      },
    );
  };

  subtest 'override' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        download => { 'bar-1.00.tar.gz' => 'fauxtar' },
      );
    };
    alien_download_ok;
    my $tarball = path($build->install_prop->{download});
    is(
      $tarball,
      object {
        call basename => 'bar-1.00.tar.gz';
        call slurp => 'fauxtar';
      },
    );
  };

};

subtest 'extract' => sub {

  subtest 'default' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        probe => 'share',
        download => 1,
        extract => 1,
      );
    };
    alien_extract_ok;
    my $dir = path($build->install_prop->{extract});
    is(
      $dir,
      object {
        call basename => 'foo-1.00';
        call [child => 'configure' ] => object {
          call slurp => path('corpus/dist/foo-1.00/configure')->slurp;
        };
        call [child => 'foo.c' ] => object {
          call slurp => path('corpus/dist/foo-1.00/foo.c')->slurp;
        };
      },
    );
  };

  subtest 'override' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        probe => 'share',
        download => 1,
        extract => {
          'bar-1.00' => {
            one => 1,
            two => 2,
            three => 3,
          },
        },
      );
    };
    alien_extract_ok;
    my $dir = path($build->install_prop->{extract});
    is(
      $dir,
      object {
        call basename => 'bar-1.00';
        call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( one two three ) ];
        call [ child => 'one' ] => object { call slurp => 1 };
        call [ child => 'two' ] => object { call slurp => 2 };
        call [ child => 'three' ] => object { call slurp => 3 };
      },
    );
  };

};

subtest 'build' => sub {

  subtest 'default' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        probe => 'share',
        download => 1,
        extract => 1,
        build => 1,
      );
    };
    alien_build_ok;
    is(
      path($build->install_prop->{_ab_build_share}),
      object {
        call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( configure foo.c foo.o libfoo.a ) ];
      },
    );
    is(
      path($build->install_prop->{prefix}),
      object {
        call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( _alien lib ) ];
        call [ child => 'lib' ] => object {
          call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( libfoo.a pkgconfig ) ];
          call [ child => 'pkgconfig' ] => object {
            call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( foo.pc ) ];
            call [ child => 'foo.pc' ] => object {
              call slurp => match qr/-lfoo/;
            };
          };
        };
      },
    );
  };

  subtest 'override' => sub {
    my $build = alienfile_ok q{
      use alienfile;
      plugin 'Test::Mock' => (
        probe => 'share',
        download => 1,
        extract => 1,
        build => [
          {
            file1 => 'content1',
          },
          {
            file2 => 'content2',
          },
        ],
      );
    };
    alien_build_ok;
    is(
      path($build->install_prop->{_ab_build_share}),
      object {
        call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( file1 configure foo.c ) ];
        call [ child => 'file1' ] => object {
          call slurp => 'content1';
        };
      },
    );
    is(
      path($build->install_prop->{prefix}),
      object {
        call_list sub { sort shift->children } => [ map { object { call basename => $_ } } sort qw( _alien file2 ) ];
        call [ child => 'file2' ] => object {
          call slurp => 'content2';
        };
      },
    );
  };
};

subtest 'gather' => sub {
  foreach my $install_type (qw( share system ))
  {

    subtest $install_type => sub {
      subtest 'default' => sub {
        my $build = alienfile_ok q{
          use alienfile;
          plugin 'Test::Mock' => (
            download => 1,
            extract  => 1,
            build    => 1,
            gather   => 1,
          );
        };
        $build->meta->register_hook(probe => sub { $install_type });
        alien_install_type_is $install_type;
        alien_build_ok;
        is(
          $build->runtime_prop,
          hash {
            field cflags => match qr/^-I/;
            field libs   => match qr/^-L.*-lfoo$/;
            etc;
          },
        );
        note "cflags = @{[ $build->runtime_prop->{cflags} ]}";
        note "libs = @{[ $build->runtime_prop->{libs} ]}";
      };
    };

    subtest $install_type => sub {
      subtest 'override' => sub {
        my $build = alienfile_ok q{
          use alienfile;
          plugin 'Test::Mock' => (
            download => 1,
            extract  => 1,
            build    => 1,
            gather   => { cflags => '-I/foo/include', libs => '-L/foo/lib -lfoo' },
          );
        };
        $build->meta->register_hook(probe => sub { $install_type });
        alien_install_type_is $install_type;
        alien_build_ok;
        is(
          $build->runtime_prop,
          hash {
            field cflags => '-I/foo/include';
            field libs   => '-L/foo/lib -lfoo';
            etc;
          },
        );
      };
    };

  };
};

done_testing;
