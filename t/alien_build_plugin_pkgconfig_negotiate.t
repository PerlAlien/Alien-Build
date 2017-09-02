use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::Negotiate;
use Alien::Build;
use Test2::Mock;
use Capture::Tiny qw( capture_merged );

subtest 'pick' => sub {

  my $pick = Alien::Build::Plugin::PkgConfig::Negotiate->pick;
  
  ok $pick, 'has a pick';
  note "pick = $pick";

};

subtest 'override' => sub {

  foreach my $name (qw( CommandLine LibPkgConf PP ))
  {
    local $ENV{ALIEN_BUILD_PKG_CONFIG} = "PkgConfig::$name";
    subtest $ENV{ALIEN_BUILD_PKG_CONFIG} => sub {
    
      foreach my $minimum_version (undef, '1.2.3')
      {
        subtest "minimum_version = @{[ $minimum_version || 'undef' ]}" => sub {

          my $plugin = Alien::Build::Plugin::PkgConfig::Negotiate->new(
            pkg_name        => 'libfoo',
            (defined $minimum_version ? (minimum_version => $minimum_version ) : ()),
          );
          
          my $build = alienfile_ok q{ use alienfile };
          
          my $subplugin;
          my %subplugin;
          
          my $mock = Test2::Mock->new(
            class => 'Alien::Build::Plugin',
          );
          
          $mock->before(subplugin => sub {
            (undef, $subplugin, %subplugin) = @_;
          });
          
          note scalar capture_merged { $plugin->init($build->meta) };
          
          is(
            [$subplugin, \%subplugin ],
            [
              "PkgConfig::$name",
              {
                pkg_name        => 'libfoo',
                minimum_version => $minimum_version,
              },
            ],
            'arguments to subplugin are correct',
          );
        }
          
      }
    
    };
  }

};

subtest 'list of pkg_name' => sub {

  my $mock = Test2::Mock->new(
    class => 'Alien::Build::Plugin',
  );

  my $subplugin;
  my %subplugin;

  $mock->before(subplugin => sub {
    (undef, $subplugin, %subplugin) = @_;
  });

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'PkgConfig' => [qw( foo bar baz )];
  };
  
  is(
    $subplugin{pkg_name},
    [ qw( foo bar baz ) ],
    'passes pkg_name correctly',
  );

  is(
    $build->requires('configure'),
    hash {
      field 'Alien::Build::Plugin::PkgConfig::Negotiate' => '0.79';
    },
    'sets prereq',
  );

};

done_testing;
