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

  skip_all 'test requires URI::file' unless has_uri_file;

  my $url = URI::file->new(path("corpus/dist")->absolute . "/");

  my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => "$url" );

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  eval { $build->load_requires('share') };
  skip_all 'test requires LWP' if $@;
  
  subtest 'listing' => sub {
    my $res = $build->fetch;
    is(
      $res,
      hash {
        field type    => 'html';
        field base    => match qr!^file:/!;
        field charset => E();
        field content => match qr!foo-1\.00\.tar\.gz!;
      },
     );
  };
  
  subtest 'file' => sub {
    my $furl = URI->new_abs("foo-1.00.tar.gz", $url);
    note "url = $furl";
    
    my $expected_content = path('corpus/dist/foo-1.00.tar.gz')->slurp_raw;
    
    my $res = $build->fetch("$furl");
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'foo-1.00.tar.gz';
        field content  => $expected_content;
      },
    );
  };
  
  subtest 'not found' => sub {
    my $furl = URI->new_abs("bogus.tar.gz", $url);
    note "url = $furl";
    eval { $build->fetch("$furl") };
    like $@, qr/^error fetching file/;
  };

};

done_testing;
