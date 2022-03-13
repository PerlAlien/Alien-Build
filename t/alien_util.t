use 5.008004;
use Test2::V0 -no_srand => 1;
use Alien::Util qw( version_cmp );


subtest 'version_cmp' => sub {

  is( version_cmp('1.0.1', '1.0.1'), 0 );
  is( version_cmp('1.0.1', '1.0.2'), -1 );
  is( version_cmp('1.0.1', '1.0.0'), 1 );

};

done_testing;
