use Test2::Bundle::Extended;
use Alien::Build::Plugin::MSYS;
use lib 't/lib';
use MyTest;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::MSYS->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::MSYS';

  my($build, $meta) = build_blank_alien_build;

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
