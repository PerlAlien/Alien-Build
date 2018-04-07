use Test2::V0 -no_srand => 1;
use Test2::Mock;
use Test::Alien::Build;
use Alien::Build;
use Path::Tiny qw( path );
use lib 'corpus/lib';
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );

subtest 'compile examples' => sub {

  foreach my $alienfile (path('example')->children(qr/\.alienfile$/))
  {
    my $build = eval {
      Alien::Build->load("$alienfile");
    };
    is $@, '', $alienfile->basename;
  }

};

subtest 'non struct alienfile' => sub {

  eval {
    alienfile q{
      use alienfile;
      my $foo = 'bar';
      @{ "${foo}::${foo}" } = ();
    };
  };
  my $error = $@;
  isnt $error, '', 'throws error';
  note "error = $error"; 

};

subtest 'warnings alienfile' => sub {

  my $warning = warning { 
    alienfile q{
      use alienfile;
      my $foo;
      my $bar = "$foo";
    };
  };
  
  ok $warning;
  note $warning;

};

subtest 'plugin' => sub {

  subtest 'basic' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'RogerRamjet';
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 22;
        field bar    => 'something generated';
        field baz    => undef;
        etc;
      }
    );
  
  };
  
  subtest 'default argument' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'RogerRamjet' => 'starscream';
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 22;
        field bar    => 'starscream';
        field baz    => undef;
        etc;
      }
    );
  
  };
  
  subtest 'other arguments' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'RogerRamjet' => (
        foo => 42,
        bar => 'skywarp',
        baz => 'megatron',
      );
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 42;
        field bar    => 'skywarp';
        field baz    => 'megatron';
        etc;
      }
    );
  
  };

  subtest 'sub package' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'NesAdvantage::Controller';
    };
    
    is($build->meta->prop->{nesadvantage}, 'controller');
  
  };
  
  subtest 'negotiate' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'NesAdvantage';
    };
    
    is($build->meta->prop->{nesadvantage}, 'negotiate');
  
  };
  
  subtest 'fully qualified class' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin '=Alien::Build::Plugin::RogerRamjet';
    };
  
    is(
      $build->meta->prop,
      hash {
        field ramjet => 'roger';
        field foo    => 22;
        field bar    => 'something generated';
        field baz    => undef;
        etc;
      }
    );
  
  };
  
};

subtest 'probe' => sub {

  subtest 'basic' => sub {

    my $build = alienfile q{
      use alienfile;
      probe sub {
        my($build) = @_;
        $build->install_prop->{called_probe} = 1;
        'share';
      };
    };
  
    is($build->probe, 'share');
    is($build->install_prop->{called_probe}, 1);
  };
  
  subtest 'wrong block' => sub {
  
    eval {
      alienfile q{
        use alienfile;
        sys {
          probe sub { };
        };
      };
    };
    
    like $@, qr/probe must not be in a system block/;
  
  };

};

subtest 'download' => sub {

  subtest 'basic' => sub {
    
    my $build = alienfile q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        download sub { path('xor-1.00.tar.gz')->touch };
      };
    };
    
    note capture_merged { $build->download; () };
    
    my $download = path($build->install_prop->{download});
    
    is(
      $download->basename,
      'xor-1.00.tar.gz',
    );
  };
  
  subtest 'wrong block' => sub {
  
    eval {
      alienfile q{
        use alienfile;
        sys {
          download sub {};
        };
      };
    };
    
    like $@, qr/download must be in a share block/;
  
  };

};

foreach my $hook (qw( fetch decode prefer extract build build_ffi ))
{

  subtest "$hook" => sub {
  
    my(undef, $build) = capture_merged {
      alienfile qq{
        use alienfile;
        share {
          $hook sub { };
        };
      };
    };
    
    ok( $build->meta->has_hook($hook) );
  
  };

}

subtest 'gather' => sub {

  subtest 'configure' => sub {
  
    eval {
      alienfile q{
        use alienfile;
        configure {
          gather sub {};
        }
      };
    };
    
    like $@, qr/gather is not allowed in configure block/;
  
  };
  
  subtest 'system + share' => sub {
  
    my $build = alienfile q{
      use alienfile;
      gather sub {};
    };
    
    is( $build->meta->has_hook('gather_system'), T() );
    is( $build->meta->has_hook('gather_share'),  T() );
  
  };

  subtest 'system' => sub {
  
    my $build = alienfile q{
      use alienfile;
      sys { gather sub {} };
    };
    
    is( $build->meta->has_hook('gather_system'), T() );
    is( $build->meta->has_hook('gather_share'),  F() );
  
  };

  subtest 'share' => sub {
  
    my $build = alienfile q{
      use alienfile;
      share { gather sub {} };
    };
    
    is( $build->meta->has_hook('gather_system'), F() );
    is( $build->meta->has_hook('gather_share'),  T() );
  
  };

  subtest 'share + gather_ffi' => sub {
  
    my(undef,$build) = capture_merged {
      alienfile q{
        use alienfile;
        share { gather_ffi sub {} };
      };
    };
  
    is( $build->meta->has_hook('gather_ffi'), T() );
  };
  

  subtest 'share + ffi gather' => sub {
  
    my $build = alienfile q{
      use alienfile;
      share { ffi { gather sub {} } };
    };
  
    is( $build->meta->has_hook('gather_ffi'), T() );
  };
  
  subtest 'nada' => sub {
  
    my $build = alienfile q{
      use alienfile;
    };
    
    is( $build->meta->has_hook('gather_system'), F() );
    is( $build->meta->has_hook('gather_share'),  F() );
  
  };

};

subtest 'prop' => sub {

  my $build = alienfile q{
    use alienfile;
    meta_prop->{foo1} = 'bar1';
  };
  
  is( $build->meta_prop->{foo1}, 'bar1' );

};

subtest 'patch' => sub {

  my $build = alienfile q{
    use alienfile;
    share { patch sub { } };
  };
  
  is( $build->meta->has_hook('patch'), T() );

};

subtest 'patch_ffi' => sub {

  my(undef,$build) = capture_merged {
    alienfile q{
      use alienfile;
      share { patch_ffi sub { } };
    };
  };
  
  is( $build->meta->has_hook('patch_ffi'), T() );

};

subtest 'ffi patch' => sub {

  my $build = alienfile q{
    use alienfile;
    share { ffi { patch sub { } } };
  };
  
  is( $build->meta->has_hook('patch_ffi'), T() );

};

subtest 'arch' => sub {

  subtest 'on' => sub {
  
    my $build = alienfile q{
      use alienfile;
      meta_prop->{arch} = 1;
    };
    
    is( $build->meta_prop->{arch}, T());
  
  };
  
  subtest 'off' => sub {

    my $build = alienfile q{
      use alienfile;
      meta_prop->{arch} = 0;
    };
  
    is( $build->meta_prop->{arch}, F());
  };
  
  subtest 'default' => sub {
    my $build = alienfile q{
      use alienfile;
    };
  
    is( $build->meta_prop->{arch}, T());
  };

};

subtest 'meta' => sub {

  my $build = alienfile q{
    use alienfile;
    meta->prop->{foo} = 1;
    probe sub { 'system' };
  
  };
  
  is $build->meta_prop->{foo}, 1;

};

subtest 'test' => sub {

  subtest 'basic' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      share {
        test [];
      };
    };
    
    is(
      $build->requires('configure'),
      hash {
        field 'Alien::Build' => '1.14';
        etc;
      },
    );
  };
  
  alienfile_ok q{
  
    use alienfile;
    
    sys {
      test [];
    };
  
  };
  
  alienfile_ok q{
  
    use alienfile;
    
    share {
      ffi {
        test [];
      };
    };
  
  };
  
  eval {
    alienfile q{
      use alienfile;
      test [];
    };
  };
  like $@, qr/test is not allowed in any block/, 'not allowed in root block';
  
  eval {
    alienfile q{
      use alienfile;
      configure { test[] };
    };
  };
  like $@, qr/test is not allowed in configure block/, 'not allowed in configure block';

};

subtest 'start_url' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    share {
      start_url 'http://bogus.com';
    };
  };
  
  is(
    $build,
    object {
      call meta_prop => hash {
        field start_url => 'http://bogus.com';
        etc;
      };
      call [requires => 'configure'] => hash {
        field 'Alien::Build' => '1.19';
        etc;
      };
    },
    'build object'
  );

};

subtest 'before' => sub {

  my $mock = Test2::Mock->new(
    class => 'Alien::Build::Meta',
  );

  my @before_hook;

  $mock->around(before_hook => sub {
    my $orig = shift;
    my (undef, $name, $code) = @_;
    push @before_hook, [$name, $code];
    $orig->(@_);
  });

  $mock->around(new => sub {
    my $orig = shift;
    @before_hook = ();
    $orig->(@_);
  });

  subtest 'before build in share' => sub {

    my $build = alienfile_ok q{
      use alienfile;
    
      share {
        before 'build' => sub {
          return 42;
        };
        build [];
      };
    };

    is $before_hook[0][0], 'build';

  };

  subtest 'before build in share>ffi' => sub {

    my $build = alienfile_ok q{
      use alienfile;
    
      share {
        ffi {
          before 'build' => sub {
            return 42;
          };
          build [];
        };
      };
    };

    is $before_hook[0][0], 'build_ffi';

  };

  subtest 'before probe in any' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      before 'probe' => sub {};
      probe [];
    };

    is $before_hook[0][0], 'probe';

  };

  subtest 'before gather any' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      before 'gather' => sub {};
      gather [];
    };

    is $before_hook[1][0], 'gather_system';
    is $before_hook[0][0], 'gather_share';

  };

  subtest 'before gather share' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      share {
        before 'gather' => sub {};
        gather [];
      };
    };

    is $before_hook[0][0], 'gather_share';

  };

  subtest 'before gather ffi' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      share {
        ffi {
          before 'gather' => sub {};
          gather [];
        };
      };
    };

    is $before_hook[0][0], 'gather_ffi';

  };

  subtest 'before gather system' => sub {

    my $build = alienfile_ok q{
      use alienfile;
      sys {
        before 'gather' => sub {};
        gather [];
      };
    };

    is $before_hook[0][0], 'gather_system';

  };

  subtest 'before build in sys' => sub {
  
    eval {
      alienfile q{
        use alienfile;
    
        sys {
          before 'build' => sub {
            return 42;
          };
          build [];
        };
      };
    };
    like $@, qr/before build is not allowed in sys block/, 'not allowed in sys block';
  
  };
  
  subtest 'before second argument must be a code ref' => sub {
  
  
    eval { 
      alienfile q{
        use alienfile;
    
        share {
          before 'build' => 1;
          build [];
        };
      };
    };
    like $@, qr/before build argument must be a code reference/, 'must be code reference';
  
  };
  
  subtest 'arbitrary stages not allowed' => sub {

    eval { 
      alienfile q{
        use alienfile;
    
        share {
          before 'bogus' => sub {};
          build [];
        };
      };
    };
    like $@, qr/No such stage bogus/, 'no bogus allowed';
  };


};

done_testing;
