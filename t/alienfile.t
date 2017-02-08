use Test2::Bundle::Extended;
use Alien::Build;
use Path::Tiny qw( path );
use lib 't/lib';
use lib 'corpus/lib';
use Capture::Tiny qw( capture_merged );
use File::Temp qw( tempdir );
use MyTest;

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
      plugin 'RogerRamjet' => ();
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
      plugin 'NesAdvantage::Controller' => ();
    };
    
    is($build->meta->prop->{nesadvantage}, 'controller');
  
  };
  
  subtest 'negotiate' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin 'NesAdvantage' => ();
    };
    
    is($build->meta->prop->{nesadvantage}, 'negotiate');
  
  };
  
  subtest 'fully qualified class' => sub {
  
    my $build = alienfile q{
      use alienfile;
      plugin '=Alien::Build::Plugin::RogerRamjet' => ();
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

foreach my $hook (qw( fetch decode prefer extract build ))
{

  subtest "$hook" => sub {
  
    my $build = alienfile qq{
      use alienfile;
      share {
        $hook sub { };
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

done_testing;
