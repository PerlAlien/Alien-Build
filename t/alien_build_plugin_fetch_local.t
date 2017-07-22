use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Local;
use Alien::Build::Util qw( _dump );
use Path::Tiny qw( path );

subtest 'basic' => sub {

  my $build = alienfile q{
    use alienfile;
    plugin 'Fetch::Local' => (
      root => 'corpus/dist',
      url  => 'foo-1.00.tar',
    );
  };
  
  subtest 'default' => sub {
  
    my $res = $build->fetch;
    
    note _dump $res;
    
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'foo-1.00.tar';
        field path     => T();
        field tmp      => 0;
        end;
      },
      'response hash'
    );
    
    ok( -f $res->{path}, 'path exists as file' );
  
  };
  
  subtest 'listing' => sub {

    my $res = $build->fetch('.');

    note _dump $res;
    
    is(
      $res,
      hash {
        field type => 'list';
        field list => array {
          foreach my $fn (qw ( foo-1.00 foo-1.00.tar foo-1.00.tar.Z foo-1.00.tar.bz2 foo-1.00.tar.gz foo-1.00.tar.xz foo-1.00.zip ))
          {
            item hash {
              field filename => $fn;
              field url => T();
              end;
            };
          }
        };
      },
      'response hash',
    );
    
    foreach my $url (map { $_->{url} } @{ $res->{list} })
    {
      ok( -e $url );
    }
  
  };


  subtest 'file' => sub {
  
    my $res = $build->fetch('foo-1.00.tar.gz');
    
    note _dump $res;
    
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'foo-1.00.tar.gz';
        field path     => T();
        field tmp      => 0;
        end;
      },
      'response hash'
    );
    
    ok( -f $res->{path}, 'path exists as file' );
  
  };
  
};

subtest 'use start_url' => sub {

  subtest 'sets start_url' => sub {
  
    my $build = alienfile_ok q{
  
      use alienfile;
    
      plugin 'Fetch::Local' => 'http://foo.bar.baz';
  
    };
  
    is $build->meta_prop->{start_url}, 'http://foo.bar.baz';
    
  };
  
  subtest 'uses start_url' => sub {
  
    my $mock = Test2::Mock->new(class => 'Alien::Build::Plugin::Fetch::Local');
    my $plugin;
    
    $mock->after(init => sub {
      my($self, $meta) = @_;
      $plugin = $self;
    });
  
    my $build = alienfile_ok q{
    
      use alienfile;
      
      meta->prop->{start_url} = 'http://baz.bar.foo';
      
      plugin 'Fetch::Local' => ();
    
    };
    
    is $plugin->url, 'http://baz.bar.foo';
  
  };

};

subtest 'uri' => sub {

  skip_all 'Test requires URI'
    unless eval q{ use URI::file; 1 };

  my $url = URI::file->new(path('corpus/dist')->absolute)->as_string;
  
  my $build = alienfile qq{
    use alienfile;
    plugin 'Fetch::Local' => (
      url  => '$url',
    );
  };


  subtest 'listing' => sub {
  
    my $res = $build->fetch($url);
    
    note _dump $res;
    
    is(
      $res,
      hash {
        field type => 'list';
        field list => array {
          foreach my $fn (qw ( foo-1.00 foo-1.00.tar foo-1.00.tar.Z foo-1.00.tar.bz2 foo-1.00.tar.gz foo-1.00.tar.xz foo-1.00.zip ))
          {
            item hash {
              field filename => $fn;
              field url => T();
              end;
            };
          }
        };
      },
      'response hash',
    );
    
    foreach my $url (map { $_->{url} } @{ $res->{list} })
    {
      ok( -e $url );
    }
  
  };

  subtest 'file' => sub {
  
    my $res = $build->fetch("$url/foo-1.00.tar.gz");
    
    note _dump $res;
    
    is(
      $res,
      hash {
        field type     => 'file';
        field filename => 'foo-1.00.tar.gz';
        field path     => T();
        field tmp      => 0;
        end;
      },
      'response hash'
    );
    
    ok( -f $res->{path}, 'path exists as file' );
  
  };

};

done_testing;
