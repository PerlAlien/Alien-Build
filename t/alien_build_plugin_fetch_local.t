use Test2::V0;
use Test::Alien::Build;
use Alien::Build::Plugin::Fetch::Local;
use Alien::Build::Util qw( _dump );
use lib 't/lib';
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
        end;
      },
      'response hash'
    );
    
    ok( -f $res->{path}, 'path exists as file' );
  
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
        end;
      },
      'response hash'
    );
    
    ok( -f $res->{path}, 'path exists as file' );
  
  };

};

done_testing;
