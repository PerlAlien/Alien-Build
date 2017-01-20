use Test2::Bundle::Extended;
use Alien::Build::Plugin::Fetch::FTP;
use lib 't/lib';
use MyTest;
use MyTest::FTP;
use Path::Tiny qw( path );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Fetch::FTP->new( url => 'ftp://localhost/' );

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'Net::FTP'}, 0 );
  is( $build->requires('share')->{'URI'}, 0 );

  note $meta->_dump;

};

subtest 'fetch' => sub {

  my $url = ftp_url;
  skip_all ftp_error unless $url;
  note "url = $url";

  my $plugin = Alien::Build::Plugin::Fetch::FTP->new( url => $url );

  my($build,$meta) = build_blank_alien_build;
  
  $plugin->init($meta);

  eval { $build->load_requires('share') };
  skip_all 'test requires Net::FTP and URI' if $@;
  
  subtest 'listing' => sub {
    my $res = $build->fetch;
    is(
      $res,
      hash {
        field type => 'list';
        field list => array {
          item hash {
            field filename => 'foo-1.00';
            field url => match qr!^ftp://!;
          };
          item hash {
            field filename => 'foo-1.00.tar.bz2';
            field url => match qr!^ftp://!;
          };
          item hash {
            field filename => 'foo-1.00.tar.gz';
            field url => match qr!^ftp://!;
          };
          item hash {
            field filename => 'foo-1.00.tar.xz';
            field url => match qr!^ftp://!;
          };
        };
      }
    );
  };
  
  subtest 'file' => sub {
    my $furl = URI->new_abs("foo-1.00.tar.gz", $url);
    note "url = $furl";
    
    my $res = $build->fetch($furl);
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'foo-1.00.tar.gz';
        field path     => match qr/foo-1\.00\.tar\.gz$/;
      },
    );
    
    my $expected = path('corpus/dist/foo-1.00.tar.gz')->slurp_raw;
    my $actual = path($res->{path})->slurp_raw;
    is( $actual, $expected );
  };
  
  subtest 'not found' => sub {
    my $furl = URI->new_abs("bogus.tar.gz", $url);
    note "url = $furl";
    eval { $build->fetch("$furl") };
    like $@, qr/^unable to fetch ftp/;
  };

};

done_testing;
