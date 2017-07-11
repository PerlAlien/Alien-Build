use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::PkgConfig::Negotiate;
use lib 't/lib';

subtest 'pick' => sub {

  my $pick = Alien::Build::Plugin::PkgConfig::Negotiate->_pick;
  
  ok $pick, 'has a pick';
  note "pick = $pick";

};

done_testing;
