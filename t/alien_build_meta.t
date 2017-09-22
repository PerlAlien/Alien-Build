use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build;

subtest 'basic' => sub {

  my $build = alienfile_ok qq{ use alienfile };
  my $meta = $build->meta;
  
  isa_ok( $build->meta, 'Alien::Build::Meta' );

};

done_testing;
