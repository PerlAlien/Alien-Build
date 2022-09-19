use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Core::Setup;
use Alien::Build::Util qw( _dump );

subtest 'compiler type' => sub {

  my $build = alienfile_ok q{
    use alienfile;
  };

  ok( $build->meta_prop->{platform}->{compiler_type}, 'has a compiler type' );
  note "compiler type = @{[ $build->meta_prop->{platform}->{compiler_type} ]}";
};

subtest 'CPU count' => sub {

  my $build = alienfile_ok q{
    use alienfile;
  };

  ok( $build->meta_prop->{platform}->{cpu}{count}, 'has a CPU count' );
  cmp_ok( $build->meta_prop->{platform}->{cpu}{count}, '>', '0',
    'CPU count is non-negative' );
  note "CPU count = @{[ $build->meta_prop->{platform}->{cpu}{count} ]}";

  subtest "ALIEN_CPU_COUNT environment variable" => sub {
    subtest "ALIEN_CPU_COUNT=1" => sub {
      local $ENV{ALIEN_CPU_COUNT} = 1;
      my $build = alienfile_ok q{
        use alienfile;
      };
      is( $build->meta_prop->{platform}->{cpu}{count}, 1, 'CPU count = 1' );
    };
    subtest "ALIEN_CPU_COUNT=2" => sub {
      local $ENV{ALIEN_CPU_COUNT} = 2;
      my $build = alienfile_ok q{
        use alienfile;
      };
      is( $build->meta_prop->{platform}->{cpu}{count}, 2, 'CPU count = 2' );
    };
    subtest "ALIEN_CPU_COUNT=0" => sub {
      local $ENV{ALIEN_CPU_COUNT} = 0;
      my $build = alienfile_ok q{
        use alienfile;
      };
      my $cpu_count = $build->meta_prop->{platform}->{cpu}{count};
      cmp_ok( $cpu_count, '>', 0, "ALIEN_CPU_COUNT=0 is ignored (value: $cpu_count)" );
    };
  };
};

subtest 'CPU arch' => sub {

  my $build = alienfile_ok q{
    use alienfile;
  };

  ok( $build->meta_prop->{platform}->{cpu}{arch}, 'has a CPU arch' );
  note "CPU arch:\n@{[ _dump($build->meta_prop->{platform}->{cpu}{arch}) ]}";
};

done_testing;
