use Test2::Bundle::Extended;
use Alien::Build::Plugin::Autoconf;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::Autoconf->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Autoconf';

  require Alien::Build;
  my $build = Alien::Build->new;
  my $meta  = $build->meta;
  
  $plugin->init($meta);
  
  my $configure = $meta->interpolator->interpolate('%{configure}');
  isnt $configure, '', "\%{configure} = $configure";
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
