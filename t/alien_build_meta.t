use Test2::V0;
use Test::Alien::Build;
use Alien::Build;

subtest 'basic' => sub {

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  isa_ok( $build->meta, 'Alien::Build::Meta' );

};

done_testing;
