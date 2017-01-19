use Test2::Bundle::Extended;
use Alien::Build::Plugin::Fetch::LWP;
use lib 't/lib';
use MyTest;
use Path::Tiny qw( path );
use constant has_uri_file => eval { require URI::file };

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => 'file://localhost/' );

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'LWP::UserAgent'}, 0 );

  note $meta->_dump;

};

subtest 'fetch' => sub {

  skip_all unless has_uri_file;

  my $url = URI::file->new(path("corpus/dist")->absolute);

  my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => $url );

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  $build->load_requires;
  
  ok 1;

};

done_testing;
