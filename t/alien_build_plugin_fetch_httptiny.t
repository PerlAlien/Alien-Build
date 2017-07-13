use Test2::V0;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::HTTPTiny;
use lib 't/lib';
use Path::Tiny qw( path );
use MyTest::HTTP;
use Alien::Build::Util qw( _dump );

subtest 'updates requires' => sub {

  my $plugin = Alien::Build::Plugin::Fetch::HTTPTiny->new( url => 'http://example.test/' );

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  $plugin->init($meta);
  
  is( $build->requires('share')->{'HTTP::Tiny'}, '0.044' );
  is( $build->requires('share')->{'URI'},         0 );

  note _dump $meta;

};

subtest 'use start_url' => sub {

  subtest 'sets start_url' => sub {
  
    my $build = alienfile_ok q{
  
      use alienfile;
    
      plugin 'Fetch::HTTPTiny' => 'http://foo.bar.baz';
  
    };
  
    is $build->meta_prop->{start_url}, 'http://foo.bar.baz';
    
  };
  
  subtest 'uses start_url' => sub {
  
    my $mock = Test2::Mock->new(class => 'Alien::Build::Plugin::Fetch::HTTPTiny');
    my $plugin;
    
    $mock->after(init => sub {
      my($self, $meta) = @_;
      $plugin = $self;
    });
  
    my $build = alienfile_ok q{
    
      use alienfile;
      
      meta->prop->{start_url} = 'http://baz.bar.foo';
      
      plugin 'Fetch::HTTPTiny' => ();
    
    };
    
    is $plugin->url, 'http://baz.bar.foo';
  
  };

};

subtest 'fetch' => sub {

  skip_all 'test requires HTTP::Tiny' unless eval q{ use HTTP::Tiny 0.044; 1 };

  my $url = http_url;
  skip_all http_error unless $url;

  my $plugin = Alien::Build::Plugin::Fetch::HTTPTiny->new( url => "$url" );

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;

  $plugin->init($meta);
  eval { $build->load_requires('share') };
  skip_all 'test requires HTTP::Tiny' if $@;
  
  subtest 'listing' => sub {
    my $res = $build->fetch;
    is(
      $res,
      hash {
        field type    => 'html';
        field base    => match qr!^http:/!;
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
    like $@, qr/^error fetching http:/;
  };
};

done_testing;
