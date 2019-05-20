use Test2::V0 -no_srand => 1;
use Alien::Build::Log;

subtest basic => sub {

  my $log = Alien::Build::Log->new;
  isa_ok $log, 'Alien::Build::Log';

};

done_testing;
