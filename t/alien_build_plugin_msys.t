use Test2::Bundle::Extended;
use Alien::Build::Plugin::MSYS;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::MSYS->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::MSYS';

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
