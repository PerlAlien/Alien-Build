use Test2::Bundle::Extended;
use Alien::Build::Plugin ();
use lib 'corpus/lib';

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin->new;
  isa_ok $plugin, 'Alien::Build::Plugin';

};

subtest 'properties' => sub {

  require Alien::Build::Plugin::RogerRamjet;

  subtest 'defaults' => sub {

    my $plugin = Alien::Build::Plugin::RogerRamjet->new;  
    is $plugin->foo, 22;
    is $plugin->bar, 'something generated';
  
  };
  
  subtest 'override' => sub {
  
    my $plugin = Alien::Build::Plugin::RogerRamjet->new(
      foo => 42,
      bar => 'anything else',
    );

    is $plugin->foo, 42;
    is $plugin->bar, 'anything else';
  
  };
  
  subtest 'set' => sub {
  
    my $plugin = Alien::Build::Plugin::RogerRamjet->new;
    
    $plugin->foo(92);
    $plugin->bar('string');
  
    is $plugin->foo, 92;
    is $plugin->bar, 'string';

  };

};

done_testing;
