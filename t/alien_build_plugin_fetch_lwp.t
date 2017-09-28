use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::LWP;
use lib 't/lib';
use Path::Tiny qw( path );
use MyTest::HTTP;
use MyTest::FTP;
use MyTest::File;
use Alien::Build::Util qw( _dump );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => 'file://localhost/' );

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'LWP::UserAgent'}, 0 );

  note _dump $meta;

};

subtest 'use start_url' => sub {

  subtest 'sets start_url' => sub {
  
    my $build = alienfile_ok q{
  
      use alienfile;
    
      plugin 'Fetch::LWP' => 'http://foo.bar.baz';
  
    };
  
    is $build->meta_prop->{start_url}, 'http://foo.bar.baz';
    
  };
  
  subtest 'uses start_url' => sub {
  
    my $mock = Test2::Mock->new(class => 'Alien::Build::Plugin::Fetch::LWP');
    my $plugin;
    
    $mock->after(init => sub {
      my($self, $meta) = @_;
      $plugin = $self;
    });
  
    my $build = alienfile_ok q{
    
      use alienfile;
      
      meta->prop->{start_url} = 'http://baz.bar.foo';
      
      plugin 'Fetch::LWP';
    
    };
    
    is $plugin->url, 'http://baz.bar.foo';
  
  };

};

subtest 'fetch' => sub {

  skip_all 'test requires HTTP::Tiny' unless eval { require HTTP::Tiny; HTTP::Tiny->VERSION(0.044); 1 };

  foreach my $type (qw( http ftp file ))
  {
    subtest "with $type" => sub {

      my $url = do {
        my $get_url = \&{"${type}_url"};
        my $error   = \&{"${type}_error"};
        my $url = $get_url->();
        skip_all $error->() unless $url;
      };

      my $plugin = Alien::Build::Plugin::Fetch::LWP->new( url => "$url" );

      my $build = alienfile filename => 'corpus/blank/alienfile';
      my $meta = $build->meta;
  
      $plugin->init($meta);
      eval { $build->load_requires('share') };
      skip_all 'test requires LWP' if $@;
  
      subtest 'listing' => sub {
        my $res = $build->fetch;
        is(
          $res,
          hash {
            if($type eq 'ftp')
            {
              field type => 'dir_listing';
            }
            else
            {
              field type    => 'html';
              field charset => E();
            }
            field base    => match qr!^$type:/!;
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
        like $@, qr/^error fetching $type:/;
      };
    };
  }
};

done_testing;
