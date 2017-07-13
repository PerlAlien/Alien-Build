use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::PP;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

$ENV{PKG_CONFIG_PATH}   = path('corpus/lib/pkgconfig')->absolute->stringify;
$ENV{PKG_CONFIG_LIBDIR} = '';

skip_all 'test requires PkgConfig 0.09026' unless eval q{ use PkgConfig 0.09026; 1 };

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
      field cflags  => '-fPIC -I/test/include/foo ';
      field libs    => '-L/test/lib -lfoo ';
      field libs_static => '-L/test/lib -lfoo -lbar -lbaz ';
      field version => '1.2.3';
      etc;
    },
  );
  
  note "cflags_static = @{[ $build->runtime_prop->{cflags_static} ]}";

};

done_testing;
