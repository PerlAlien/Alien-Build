use Test2::V0;
use Alien::Build::Plugin::PkgConfig::LibPkgConf;
use Path::Tiny qw( path );
use lib 't/lib';
use MyTest;
use Capture::Tiny qw( capture_merged );

$ENV{PKG_CONFIG_PATH}   = path('corpus/lib/pkgconfig')->absolute->stringify;
$ENV{PKG_CONFIG_LIBDIR} = '';

sub build
{
  my($build, $meta) = build_blank_alien_build;
  my $plugin = Alien::Build::Plugin::PkgConfig::LibPkgConf->new(@_);
  $plugin->init($meta);
  ($build, $meta, $plugin);
}

skip_all 'Test requires PkgConfig::LibPkgConf'
  unless eval {
    my($build, $meta, $plugin) = build(pkg_name => 'foo', minimum_version => 1);
    $build->load_requires('configure');
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
  
};

done_testing;
