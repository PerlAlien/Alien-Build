use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::MSYS;
use lib 't/lib';

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::Build::MSYS->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Build::MSYS';

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

  $plugin->init($meta);

};

done_testing;


{
  package
    Alien::MSYS;
    
  BEGIN {
    our $VERSION = '0.07';
    $INC{'Alien/MSYS.pm'} = __FILE__;
  }
  
}
