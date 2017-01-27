use Test2::Bundle::Extended;
use lib 't/lib';
use MyTest::System2;
use MyTest;
use Alien::Build::Plugin::Probe::CommandLine;
use IPC::Cmd;

sub build 
{
  my($build, $meta) = build_blank_alien_build;
  
  if(ref $_[-1] eq 'CODE')
  {
    my $code = pop;
    $code->($build, $meta);
  }
  
  my $plugin = Alien::Build::Plugin::Probe::CommandLine->new(@_);
  $plugin->init($meta);
  ($build, $plugin, $meta);
}

subtest 'basic existence' => sub {

  my $guard = system_fake
    'foo' => sub { return 0 },
  ;
  
  subtest 'it is there' => sub {
  
    my($build) = build('foo');
    is $build->probe, 'system', 'is system';
  
  };
  
  subtest 'it is not there' => sub {

    my($build) = build('bar');
    is $build->probe, 'share', 'is share';

  };

};

subtest 'args' => sub {

  my $called = 0;
  my @args;

  my $guard = system_fake
    'foo' => sub { $called = 1; @args = @_; return 0 },
  ;
  
  my($build) = build(command => 'foo', args => [1,2,3], match => qr// );
  
  is $build->probe, 'system', 'is system';
  
  is $called, 1, 'was called';
  
  is \@args, [1,2,3], 'args are passed in';

};

subtest 'secondary' => sub {

  my $lib = 0;
  my $run = 0;

  my $guard = system_fake
    'foo' => sub { $run = 1; return 0 },
  ;
  
  subtest 'libs + command okay' => sub {
  
    $lib = 0;
    $run = 0;
  
    my($build) = build(command => 'foo', secondary => 1, match => qr//, sub {
      my($build, $meta) = @_;
      $meta->register_hook(probe => sub {
        $lib = 1;
        'system';
      });
    });
    
    is($build->probe, 'system');
    is $run, 1, 'run';
    is $lib, 1, 'lib';
  
  };

  subtest 'libs ok + command bad' => sub {
  
    $lib = 0;
    $run = 0;
  
    my($build) = build(command => 'bar', secondary => 1, match => qr//, sub {
      my($build, $meta) = @_;
      $meta->register_hook(probe => sub {
        $lib = 1;
        'system';
      });
    });
    
    is($build->probe, 'share');
    is $lib, 1, 'lib';
  
  };

  subtest 'libs bad + command okay' => sub {
  
    $lib = 0;
    $run = 0;
  
    my($build) = build(command => 'foo', secondary => 1, match => qr//, sub {
      my($build, $meta) = @_;
      $meta->register_hook(probe => sub {
        $lib = 1;
        'share';
      });
    });
    
    is($build->probe, 'share');
    is $run, 0, 'run';
    is $lib, 1, 'lib';
  
  };

  subtest 'libs bad + command bad' => sub {
  
    $lib = 0;
    $run = 0;
  
    my($build) = build(command => 'bar', secondary => 1, match => qr//, sub {
      my($build, $meta) = @_;
      $meta->register_hook(probe => sub {
        $lib = 1;
        'share';
      });
    });
    
    is($build->probe, 'share');
    is $run, 0, 'run';
    is $lib, 1, 'lib';
  
  };

};

subtest 'match + version' => sub {

  my $guard = system_fake
    'foo' => sub { print "Froodle Foomaker version 1.00\n"; return 0 },
  ;
  
  subtest 'match good' => sub {
    my($build) = build(command => 'foo', match => qr/Froodle/);
    is $build->probe, 'system';
  };

  subtest 'match bad' => sub {
    my($build) = build(command => 'foo', match => qr/Droodle/);
    is $build->probe, 'share';
  };
  
  subtest 'version found' => sub {
    my($build) = build(command => 'foo', version => qr/version ([0-9\.]+)/);
    is $build->probe, 'system';
    is $build->runtime_prop->{version}, '1.00';
  };
  
  subtest 'version unfound' => sub {
    my($build) = build(command => 'foo', version => qr/version = ([0-9\.]+)/);
    is $build->probe, 'system';
    is $build->runtime_prop->{version}, undef;
  };

};

done_testing;

