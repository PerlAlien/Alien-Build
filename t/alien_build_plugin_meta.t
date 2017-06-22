use Test2::V0;
use lib 'corpus/lib';
use Alien::Build::Plugin::RogerRamjet;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::RogerRamjet->new;

  isa_ok( $plugin->meta, 'Alien::Build::PluginMeta' );

};

done_testing;
