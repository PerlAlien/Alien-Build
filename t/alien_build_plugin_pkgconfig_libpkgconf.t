use Test2::V0 -no_srand => 1;
use lib 'corpus/lib';
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::LibPkgConf;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

$ENV{PKG_CONFIG_PATH}   = path('corpus/lib/pkgconfig')->absolute->stringify;
$ENV{PKG_CONFIG_LIBDIR} = '';

sub build
{
  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  my $plugin = Alien::Build::Plugin::PkgConfig::LibPkgConf->new(@_);
  $plugin->init($meta);
  ($build, $meta, $plugin);
}

skip_all 'Test requires PkgConfig::LibPkgConf'
  unless eval {
    my($build, $meta, $plugin) = build(pkg_name => 'foo', minimum_version => 1);
    $build->load_requires('configure');
  };

subtest 'available' => sub {

  local $INC{'PkgConfig/LibPkgConf.pm'} = __FILE__;

  subtest 'new enough' => sub {
    local $PkgConfig::LibPkgConf::VERSION = '0.04';
    is(Alien::Build::Plugin::PkgConfig::LibPkgConf->available, T());
  };

  subtest 'too old!' => sub {
    local $PkgConfig::VERSION = '0.03';
    is(Alien::Build::Plugin::PkgConfig::LibPkgConf->available, F());
  };

};

ok $INC{'PkgConfig/LibPkgConf/Client.pm'}, 'Loaded PkgConfig::LibPkgConf::Client';
note "inc=$INC{'PkgConfig/LibPkgConf/Client.pm'}";
ok $INC{'PkgConfig/LibPkgConf/Util.pm'}, 'Loaded PkgConfig::LibPkgConf::Util';
note "inc=$INC{'PkgConfig/LibPkgConf/Util.pm'}";

note "PKG_CONFIG_PATH=$ENV{PKG_CONFIG_PATH}";

subtest 'system not available' => sub {

  my($build, $meta, $plugin) = build('bogus');

  my($out, $type) = capture_merged { $build->probe };
  note $out;

  is( $type, 'share' );

};

subtest 'version requirements' => sub {

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

    subtest 'max version (lot less)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        max_version => '1.0.0',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );

    };

    subtest 'max version (less)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        max_version => '1.2.2',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'share' );

    };

    subtest 'max version (exact)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        max_version => '1.2.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );

    };

    subtest 'max version (more)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        max_version => '1.2.4',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );

    };

    subtest 'max version (lots more)' => sub {

      my($build, $meta, $plugin) = build(
        pkg_name => 'foo',
        max_version => '3.3.3',
      );

      my($out, $type) = capture_merged { $build->probe };
      note $out;

      is( $type, 'system' );

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
      field cflags        => '-fPIC -I/test/include/foo ';
      field cflags_static => '-fPIC -I/test/include/foo -DFOO_STATIC ';
      field libs          => '-L/test/lib -lfoo ';
      field libs_static   => '-L/test/lib -lfoo -lbar -lbaz ';
      field version       => '1.2.3';
      etc;
    },
  );

  is(
    $build->runtime_prop->{alt},
    U(),
  );

};

subtest 'system multiple' => sub {

  subtest 'all found in system' => sub {

    my $build = alienfile_ok q{

      use alienfile;
      plugin 'PkgConfig::LibPkgConf' => (
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
      plugin 'PkgConfig::LibPkgConf' => 'foo';
    };

    is(
      $build->requires('configure'),
      hash {
        field 'PkgConfig::LibPkgConf::Client' => T();
        etc;
      },
      'prereqs'
    );

  };

  subtest 'minimum version requires util module' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      plugin 'PkgConfig::LibPkgConf' => (
        pkg_name => 'foo',
        minimum_version => '1.00',
      );
    };

    is(
      $build->requires('configure'),
      hash {
        field 'PkgConfig::LibPkgConf::Client' => T();
        field 'PkgConfig::LibPkgConf::Util' => T();
        etc;
      },
      'prereqs'
    );
  };

  subtest 'are not specified when user asks for plugin IN-directly' => sub {

    local $ENV{ALIEN_BUILD_PKG_CONFIG} = 'PkgConfig::LibPkgConf';

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

  my $build = alienfile_ok q{
    use alienfile;

    plugin 'PkgConfig::LibPkgConf' => ( pkg_name => 'totally-bogus-pkg-config-name' );

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
