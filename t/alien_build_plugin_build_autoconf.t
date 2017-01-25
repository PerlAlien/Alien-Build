use Test2::Bundle::Extended;
use Alien::Build::Plugin::Build::Autoconf;
use lib 't/lib';
use MyTest;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::Build::Autoconf->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Build::Autoconf';

  my($build, $meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  
  my $configure = $meta->interpolator->interpolate('%{configure}');
  isnt $configure, '', "\%{configure} = $configure";
  like $configure, qr{configure};
  like $configure, qr{--with-pic};
};

subtest 'turn off --with-pic' => sub {

  my $plugin = Alien::Build::Plugin::Build::Autoconf->new( with_pic => 0 );

  is( $plugin->with_pic, 0 );
  
  my($build, $meta) = build_blank_alien_build;
  
  $plugin->init($meta);

  my $configure = $meta->interpolator->interpolate('%{configure}');
  isnt $configure, '', "\%{configure} = $configure";
  like $configure, qr{configure$};

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
