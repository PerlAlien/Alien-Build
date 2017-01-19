use Test2::Bundle::Extended;
use Alien::Build::Plugin ();

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin->new;
  isa_ok $plugin, 'Alien::Build::Plugin';

};

done_testing;
