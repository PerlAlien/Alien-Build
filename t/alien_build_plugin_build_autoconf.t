use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::Autoconf;

subtest 'basic' => sub {

  my $plugin = Alien::Build::Plugin::Build::Autoconf->new;
  isa_ok $plugin, 'Alien::Build::Plugin';
  isa_ok $plugin, 'Alien::Build::Plugin::Build::Autoconf';

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  $plugin->init($meta);
  
  my $configure = $meta->interpolator->interpolate('%{configure}');
  isnt $configure, '', "\%{configure} = $configure";
  like $configure, qr{configure};
  like $configure, qr{--with-pic};
  
  is($build->meta_prop->{destdir}, 1);
  is($meta->prop->{destdir}, 1);
};

subtest 'turn off --with-pic' => sub {

  my $plugin = Alien::Build::Plugin::Build::Autoconf->new( with_pic => 0 );

  is( $plugin->with_pic, 0 );
  
  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
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
