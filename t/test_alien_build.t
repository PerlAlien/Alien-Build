use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny qw( path );

subtest 'alienfile_ok' => sub {

  subtest 'inline' => sub {

    my $build = alienfile q{
      use alienfile;
    };
  
    isa_ok $build, 'Alien::Build';

    ok(-d $build->install_prop->{prefix}, "has prefix dir");
    note "prefix = @{[ $build->install_prop->{prefix} ]}";

    ok(-d $build->install_prop->{root}, "has root dir");
    note "root = @{[ $build->install_prop->{root} ]}";

    ok(-d $build->install_prop->{stage}, "has stage dir");
    note "stage = @{[ $build->install_prop->{stage} ]}";

  };

  subtest 'from file' => sub {

    my $build = alienfile filename => 'corpus/basic/alienfile';
  
    isa_ok $build, 'Alien::Build';

    ok(-d $build->install_prop->{prefix}, "has prefix dir");
    note "prefix = @{[ $build->install_prop->{prefix} ]}";

    ok(-d $build->install_prop->{root}, "has root dir");
    note "root = @{[ $build->install_prop->{root} ]}";

    ok(-d $build->install_prop->{stage}, "has stage dir");
    note "stage = @{[ $build->install_prop->{stage} ]}";

  };

  my $ret;

  $ret = alienfile_ok q{ use alienfile };
  isa_ok($ret, 'Alien::Build');

  alienfile_ok filename => 'corpus/basic/alienfile';

  is(
    intercept { $ret = alienfile_ok q{ bogus alienfile stuff } },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'alienfile compiles';
      };
      event Diag => sub {};
      event Diag => sub {};
      end;
    },
    'compile error in alienfile fails test'
  );

  alienfile_ok q{
    use alienfile;
  
    log('hey there');
  };

};

subtest alien_build_ok => sub {

  subtest 'no alienfile' => sub {
  
    eval { alienfile q{ die } };
    
    my $ret;
    
    is(
      intercept { $ret = alien_build_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'alien builds okay';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'no alienfile';
        };
        end;
      },
    );
    
    is $ret, U();
  
  };
  
  subtest 'alienfile compiles but does not run' => sub {
  
    alienfile_ok q{
      use alienfile;
      
      probe sub { 'share' };
      
      share {
        download sub { die 'dinosaurs and transformers' };
        build sub {};
      }
    };
    
    my $ret;
    
    is(
      intercept { $ret = alien_build_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'alien builds okay';
        };
        event Diag => sub {};
        event Diag => sub {};
        event Diag => sub {
          call message => match(qr/build threw exception: dinosaurs and transformers/);
        };
        end;
      },
    );
  
    is $ret, U();
  };
  
  subtest 'good system' => sub {
  
    alienfile_ok q{
      use alienfile;
      probe sub { 'system' };
      sys {
        gather sub {
          my($build) = @_;
          $build->runtime_prop->{cflags} = '-DFOO=1';
          $build->runtime_prop->{libs}   = '-lfoo';
        };
      };
    };
    
    my $alien = alien_build_ok;
    
    isa_ok $alien, 'Alien::Base';
    
    is $alien->cflags,  '-DFOO=1';
    is $alien->libs,    '-lfoo';
  
  };
  
  subtest 'good share' => sub {
  
    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        download sub { path('file1')->touch };
        extract sub { path('file2')->touch };
        build sub {
          my($build) = @_;
          path($build->install_prop->{stage})->child('file3')->touch;
        };
        gather sub {
          my($build) = @_;
          my $prefix = $build->runtime_prop->{prefix};
          $build->runtime_prop->{cflags} = "-I$prefix/include -DFOO=1";
          $build->runtime_prop->{libs}   = "-L$prefix/lib -lfoo";
        };
      };
    };
    
    my $alien = alien_build_ok;
    
    isa_ok $alien, 'Alien::Base';
    
    my $prefix = $alien->runtime_prop->{prefix};
    
    is $alien->cflags, "-I$prefix/include -DFOO=1";
    is $alien->libs,   "-L$prefix/lib -lfoo";
    
    ok -f path($prefix)->child('file3');
  };

};

subtest 'alien_install_type_is' => sub {


  my $ret;

  subtest 'no alienfile' => sub {

    eval { alienfile q{ die } };
    
    is(
      intercept { $ret = alien_install_type_is 'system' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'alien install type is system';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'no alienfile';
        };
        end;
      },
      'test for anything',
    );
  
    is $ret, F(), 'return false';
  };
  
  subtest 'is system' => sub {
  
    alienfile_ok q{
      use alienfile;
      probe sub { 'system' };
    };
    
    is(
      intercept { $ret = alien_install_type_is 'system', 'some name' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'some name';
        };
        end;
      },
      'check for system',
    );
    
    is $ret, T(), 'return true';

    is(
      intercept { $ret = alien_install_type_is 'share', 'some name' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'some name';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'expected install type of share, but got system';
        };
        end;
      },
      'check for share',
    );
    
    is $ret, F(), 'return false';
  
  };

  subtest 'is share' => sub {
  
    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
    };
    
    is(
      intercept { $ret = alien_install_type_is 'share', 'some other name' },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'some other name';
        };
        end;
      },
      'check for share',
    );
    
    is $ret, T(), 'return true';

    is(
      intercept { $ret = alien_install_type_is 'system', 'some other name' },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'some other name';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'expected install type of system, but got share';
        };
        end;
      },
      'check for system',
    );
    
    is $ret, F(), 'return false';
  
  };
  
};

subtest 'alien_extract_ok' => sub {

  subtest 'good extract' => sub {
  
    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        download sub {
          path('file1')->touch;
        };
        extract sub {
          path($_)->touch for qw( file2 file3 );
        };
      };
    };
    
    alien_extract_ok;
  
  };
  
  subtest 'bad extract' => sub {

    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        download sub {
          path('file1')->touch;
        };
        extract sub {
          ();
        };
      };
    };
    
    is(
      intercept { alien_extract_ok },
      array {
        event Ok => sub {
          call pass => F();
        };
        etc;
      },
    );
  };
  
};

done_testing;
