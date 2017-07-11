use Test2::V0;
use Test::Alien::Build;

subtest 'inline' => sub {

  my $build = alienfile q{
    use alienfile;
  };
  
  isa_ok $build, 'Alien::Build';

  ok(-d $build->install_prop->{prefix}, "has prefix dir");
  note "prefix = @{[ $build->install_prop->{prefix} ]}";

  ok(-d $build->install_prop->{root}, "has root dir");
  note "root = @{[ $build->install_prop->{root} ]}";

  ok(-d $build->install_prop->{stage}, "has stage dir");
  note "stage = @{[ $build->install_prop->{stage} ]}";

};

subtest 'from file' => sub {

  my $build = alienfile filename => 'corpus/basic/alienfile';
  
  isa_ok $build, 'Alien::Build';

  ok(-d $build->install_prop->{prefix}, "has prefix dir");
  note "prefix = @{[ $build->install_prop->{prefix} ]}";

  ok(-d $build->install_prop->{root}, "has root dir");
  note "root = @{[ $build->install_prop->{root} ]}";

  ok(-d $build->install_prop->{stage}, "has stage dir");
  note "stage = @{[ $build->install_prop->{stage} ]}";

};

done_testing;
