use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::MSYS;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::Build::MSYS->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Build::MSYS';

  my $build = alienfile_ok q{ use alienfile };
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
