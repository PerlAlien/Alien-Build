use Test2::V0;
use Alien::Build;
use lib 't/lib';
use MyTest;

subtest 'basic' => sub {

  my($build, $meta) = build_blank_alien_build;
  
  isa_ok( $build->meta, 'Alien::Build::Meta' );

};

done_testing;
