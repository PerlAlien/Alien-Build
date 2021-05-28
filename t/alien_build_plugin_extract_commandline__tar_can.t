use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Extract::CommandLine;

eval { require Readonly; Readonly->VERSION('1.60') }; ## no critic (Community::PreferredAlternatives)
skip_all 'test requires Readonly 1.60' if $@;

subtest 'tar can' => sub {
  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

  my $plugin = Alien::Build::Plugin::Extract::CommandLine->new;

  Readonly::Scalar($_ => 'a');
  $plugin->init($meta);

  ok lives {
    $plugin->_tar_can('.tar.gz');
  }, 'can read from <DATA> with readonly $_' or note($@);
};

done_testing;
