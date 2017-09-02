use Test2::V0 -no_srand => 1;
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

subtest 'system available, wrong version' => sub {

  my($build, $meta, $plugin) = build(
    pkg_name => 'foo',
    minimum_version => '1.2.4',
  );
  
  my($out, $type) = capture_merged { $build->probe };
  note $out;
  
  is( $type, 'share' );

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

done_testing;
