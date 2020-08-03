use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::Negotiate;
use Alien::Build;
use Capture::Tiny qw( capture_merged );

subtest 'pick' => sub {

  my $pick = Alien::Build::Plugin::PkgConfig::Negotiate->pick;

  ok $pick, 'has a pick';
  note "pick = $pick";

};

subtest 'override' => sub {

  foreach my $name (qw( PP LibPkgConf CommandLine ))
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

          my $mock = mock 'Alien::Build::Meta';

          $mock->before(apply_plugin => sub {
            (undef, $subplugin, %subplugin) = @_;
          });

          note scalar capture_merged { $plugin->init($build->meta) };

          is(
            [$subplugin, \%subplugin ],
            [
              "PkgConfig::$name",
              hash {
                field pkg_name         => 'libfoo';
                field minimum_version  => $minimum_version if defined $minimum_version;
                field register_prereqs => 0;
                end;
              },
            ],
            'arguments to subplugin are correct',
          );
        }

      }

    };
  }

};

subtest 'version stuff' => sub {

  my $class = 'Alien::Build::Plugin::PkgConfig::Negotiate';

  my $getmeta = sub {
    mock { reqs => {}, apply => [] } => (
      add => [
        add_requires => sub {
          my($self, $phase, $name, $version) = @_;
          $version = '0' unless defined $version;
          $self->{reqs}->{$phase}->{$name} = $version;
        },
      ],
      add => [
        apply_plugin => sub {
          my($self, undef, %args) = @_;
          push @{ $self->{apply} }, \%args;
        },
      ],
    );
  };

  my $mock = mock 'Alien::Build' => (
    override => [
      log => sub {
        my(undef, $message) = @_;
        note $message;
      },
    ],
  );

  subtest 'nodda' => sub {

    my $meta = $getmeta->();

    my $plugin = $class->new(
      pkg_name => 'libfoo',
    );

    $plugin->init($meta);

    is(
      $meta->{reqs},
      {},
      'reqs',
    );

    is(
      $meta->{apply},
      [hash {
        field pkg_name => 'libfoo';
        field register_prereqs => 0;
        end;
      }],
      'apply',
    );

  };

  subtest 'minimum_version' => sub {

    my $meta = $getmeta->();

    my $plugin = $class->new(
      pkg_name        => 'libfoo',
      minimum_version => '1.2.3',
    );

    $plugin->init($meta);

    is(
      $meta->{reqs},
      {},
      'reqs',
    );

    is(
      $meta->{apply},
      [hash {
        field pkg_name => 'libfoo';
        field register_prereqs => 0;
        field minimum_version => '1.2.3';
        end;
      }],
      'apply',
    );

  };

  subtest 'atleast_version' => sub {

    my $meta = $getmeta->();

    my $plugin = $class->new(
      pkg_name        => 'libfoo',
      atleast_version => '1.2.3',
    );

    $plugin->init($meta);

    is(
      $meta->{reqs},
      { configure => { 'Alien::Build::Plugin::PkgConfig::Negotiate' => '1.53' }},
      'reqs',
    );

    is(
      $meta->{apply},
      [hash {
        field pkg_name => 'libfoo';
        field register_prereqs => 0;
        field atleast_version => '1.2.3';
        end;
      }],
      'apply',
    );

  };

  subtest 'exact_version' => sub {

    my $meta = $getmeta->();

    my $plugin = $class->new(
      pkg_name      => 'libfoo',
      exact_version => '1.2.3',
    );

    $plugin->init($meta);

    is(
      $meta->{reqs},
      { configure => { 'Alien::Build::Plugin::PkgConfig::Negotiate' => '1.53' }},
      'reqs',
    );

    is(
      $meta->{apply},
      [hash {
        field pkg_name => 'libfoo';
        field register_prereqs => 0;
        field exact_version => '1.2.3';
        end;
      }],
      'apply',
    );

  };

  subtest 'max_version' => sub {

    my $meta = $getmeta->();

    my $plugin = $class->new(
      pkg_name    => 'libfoo',
      max_version => '1.2.3',
    );

    $plugin->init($meta);

    is(
      $meta->{reqs},
      { configure => { 'Alien::Build::Plugin::PkgConfig::Negotiate' => '1.53' }},
      'reqs',
    );

    is(
      $meta->{apply},
      [hash {
        field pkg_name => 'libfoo';
        field register_prereqs => 0;
        field max_version => '1.2.3';
        end;
      }],
      'apply',
    );

  };

};

subtest 'list of pkg_name' => sub {

  my $mock = mock 'Alien::Build::Meta';
  my $subplugin;
  my @subplugin;

  $mock->before(apply_plugin => sub {
    (undef, $subplugin, @subplugin) = @_ if $_[1] eq 'PkgConfig';
  });

  my $build = alienfile_ok q{
    use alienfile;
    plugin 'PkgConfig' => [qw( foo bar baz )];
  };

  is(
    \@subplugin,
    [ [ qw( foo bar baz ) ] ],
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
