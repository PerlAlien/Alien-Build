use Test2::V0 -no_srand => 1;
use lib 'corpus/lib';
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::PP;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

$ENV{PKG_CONFIG_PATH}   = path('corpus/lib/pkgconfig')->absolute->stringify;
$ENV{PKG_CONFIG_LIBDIR} = '';

skip_all 'test requires PkgConfig 0.14026' unless eval { require PkgConfig; PkgConfig->VERSION(0.14026) };

subtest 'available' => sub {

  local $INC{'PkgConfig.pm'} = __FILE__;

  subtest 'new enough' => sub {
    local $PkgConfig::VERSION = '0.14026';
    is(Alien::Build::Plugin::PkgConfig::PP->available, T());
  };

  subtest 'too old!' => sub {
    local $PkgConfig::VERSION = '0.14025';
    is(Alien::Build::Plugin::PkgConfig::PP->available, F());
  };

};

sub build
{
  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  my $plugin = Alien::Build::Plugin::PkgConfig::PP->new(@_);
  $plugin->init($meta);
  ($build, $meta, $plugin);
}

note "PKG_CONFIG_PATH=$ENV{PKG_CONFIG_PATH}";

subtest 'system not available' => sub {

  my($build, $meta, $plugin) = build('bogus');

  my($out, $type) = capture_merged { $build->probe };
  note $out;

  is( $type, 'share' );

};

subtest 'system available, wrong version' => sub {

  subtest 'atleast_version or minimum_version' => sub {

    subtest 'old name bad' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        minimum_version => '1.2.4',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );
    };

    subtest 'old name good (exact)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        minimum_version => '1.2.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );
    };

    subtest 'old name good (much older)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        minimum_version => '1.1.1',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );
    };

    subtest 'atleast_version bad' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        atleast_version => '1.2.4',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );
    };

    subtest 'atleast_version good (exact)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        atleast_version => '1.2.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );
    };

    subtest 'atleast_version good (older)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        atleast_version => '1.1.1',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );
    };
  };

  subtest 'exact' => sub {

    subtest 'exact version (less)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '1.2.2',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );

    };

    subtest 'exact version (exact)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '1.2.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );

    };

    subtest 'exact version (more)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '1.2.4',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );

    };

  };

  subtest 'max_version' => sub {

    subtest 'max version (less)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '1.0.0',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );

    };

    subtest 'max version (exact)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '1.2.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );

    };

    subtest 'max version (more)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '1.2.4',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );

    };

    subtest 'max version (lots more)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        exact_version => '3.3.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );

    };

  };
};

subtest 'system available, okay' => sub {

  my($build, $meta, $plugin) = build(
    pkg_name => 'foo',
    minimum_version => '1.2.3',
  );

  my($out, $type) = capture_merged { $build->probe };
  note $out;

  is( $type, 'system' );

  return unless $type eq 'system';

  note capture_merged { $build->build; () };

  is(
    $build->runtime_prop,
    hash {
      field cflags  => '-fPIC -I/test/include/foo ';
      field libs    => '-L/test/lib -lfoo ';
      field libs_static => '-L/test/lib -lfoo -lbar -lbaz ';
      field version => '1.2.3';
      etc;
    },
  );

  note "cflags_static = @{[ $build->runtime_prop->{cflags_static} ]}";

  is(
    $build->runtime_prop->{alt},
    U(),
  );

};

subtest 'system multiple' => sub {

  subtest 'all found in system' => sub {

    my $build = alienfile_ok q{

      use alienfile;
      plugin 'PkgConfig::PP' => (
        pkg_name => [ 'xor', 'xor-chillout' ],
      );

    };

    alien_install_type_is 'system';

    my $alien = alien_build_ok;

    use Alien::Build::Util qw( _dump );
    note _dump($alien->runtime_prop);

    is(
      $alien->runtime_prop,
      hash {
        field libs          => '-L/test/lib -lxor ';
        field libs_static   => '-L/test/lib -lxor -lxor1 ';
        field cflags        => '-I/test/include/xor ';
        field cflags_static => '-I/test/include/xor -DXOR_STATIC ';
        field version       => '4.2.1';
        field alt => hash {
          field 'xor' => hash {
            field libs          => '-L/test/lib -lxor ';
            field libs_static   => '-L/test/lib -lxor -lxor1 ';
            field cflags        => '-I/test/include/xor ';
            field cflags_static => '-I/test/include/xor -DXOR_STATIC ';
            field version       => '4.2.1';
            end;
          };
          field 'xor-chillout' => hash {
            field libs          => '-L/test/lib -lxor-chillout ';
            field libs_static   => '-L/test/lib -lxor-chillout ';
            field cflags        => '-I/test/include/xor ';
            field cflags_static => '-I/test/include/xor -DXOR_STATIC ';
            field version       => '4.2.2';
          };
          end;
        };
        etc;
      },
    );
  };

};

subtest 'prereqs' => sub {

  subtest 'are specified when user asks for plugin directly' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      plugin 'PkgConfig::PP' => 'foo';
    };

    is(
      $build->requires('configure'),
      hash {
        field 'PkgConfig' => T();
        etc;
      },
      'prereqs'
    );

  };

  subtest 'are not specified when user asks for plugin IN-directly' => sub {

    local $ENV{ALIEN_BUILD_PKG_CONFIG} = 'PkgConfig::PP';

    my $build = alienfile_ok q{
      use alienfile;
      plugin 'PkgConfig' => 'foo';
    };

    is(
      $build->requires('configure'),
      hash {
        field 'PkgConfig'                     => DNE();
        field 'PkgConfig::LibPkgConf::Client' => DNE();
        field 'PkgConfig::LibPkgConf::Util'   => DNE();
        etc;
      },
      'prereqs'
    );

  };
};

alien_subtest 'set env' => sub {

  skip_all 'test requires Archive::Tar' unless eval { require Archive::Tar; 1 };

  my $build = alienfile_ok q{
    use alienfile;

    plugin 'PkgConfig::PP' => ( pkg_name => 'totally-bogus-pkg-config-name' );

    probe sub { 'share' };

    share {

      plugin 'Download::Foo';

      build sub {
        my($build) = @_;
        $build->log("PKG_CONFIG = $ENV{PKG_CONFIG}");
        1;
      };

      meta->around_hook(
        gather_share => sub {
          1;
        },
      );
    };

  };

  alien_build_ok;

};

done_testing;
