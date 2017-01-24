use Test2::Bundle::Extended;
use Alien::Build;
use lib 't/lib';
use lib 'corpus/lib';
use MyTest;
use MyTest::System2;
use Capture::Tiny qw( capture_merged );
use File::chdir;
use Path::Tiny qw( path );

subtest 'simple new' => sub {
  my $build = MyBuild->new;
  
  isa_ok $build, 'Alien::Build';

  isa_ok( $build->meta, 'Alien::Build::Meta' );
  isa_ok( MyBuild->meta, 'Alien::Build::Meta' );
  note($build->meta->_dump);

};

subtest 'from file' => sub {

  my $build = Alien::Build->load('corpus/basic/alienfile');
  
  isa_ok $build, 'Alien::Build';

  isa_ok( $build->meta, 'Alien::Build::Meta' );

  note($build->meta->_dump);

  is( $build->requires,              { Foo => '1.00' },                'any'       );
  is( $build->requires('share'),     { Foo => '1.00', Bar => '2.00' }, 'share'     );
  is( $build->requires('system'),    { Foo => '1.00', Baz => '3.00' }, 'system'    );
  is( $build->requires('configure'), { 'Early::Module' => '1.234' },   'configure' );

  my $intr = $build->meta->interpolator;
  isa_ok $intr, 'Alien::Build::Interpolate::Default';

};

subtest 'invalid alienfile' => sub {

  eval { Alien::Build->load('corpus/basic/alienfilex') };
  like $@, qr{Unable to read alienfile: };

};

subtest 'load requires' => sub {

  my($build, $meta) = build_blank_alien_build;
  
  note($meta->_dump);
  
  is( $build->load_requires, 1, 'empty loads okay' );

  $meta->add_requires( 'any' => 'Foo::Bar::Baz' => '1.00');
  is( $build->load_requires, 1, 'have it okay' );
  ok $INC{'Foo/Bar/Baz.pm'};
  note "inc=$INC{'Foo/Bar/Baz.pm'}";

  $meta->add_requires( 'any' => 'Foo::Bar::Baz1' => '2.00');
  eval { $build->load_requires };
  my $error = $@;
  isnt $error, '';
  note "error=$error";
};

subtest 'hook' => sub {

  my($build, $meta) = build_blank_alien_build;
  
  subtest 'simple single working hook' => sub {
  
    my @foo1;
  
    $meta->register_hook(
      foo1 => sub {
        @foo1 = @_;
        return 42;
      }
    );
  
    is( $build->_call_hook(foo1 => ('roger', 'ramjet')), 42);
    is(
      \@foo1,
      array {
        item object {
          prop blessed => ref $build;
          call sub { shift->isa('Alien::Build') } => T();
        };
        item 'roger';
        item 'ramjet';
      }
    );
  };

  my $exception_count = 0;
  
  $meta->register_hook(
    foo2 => sub {
      $exception_count++;
      die "throw exception";
    }
  );
  
  subtest 'single failing hook' => sub {
    
    $exception_count = 0;
    
    eval { $build->_call_hook(foo2 => ()) };
    like $@, qr/throw exception/;
    note "error = $@";
    is $exception_count, 1;
  
  };
  
  subtest 'one fail, one okay' => sub {
  
    $exception_count = 0;
    
    $meta->register_hook(
      foo2 => sub {
        99;
      }
    );
    
    is( $build->_call_hook(foo2 => ()), 99);
    is $exception_count, 1;
  
  };
  
  subtest 'invalid hook' => sub {
  
    eval { $build->_call_hook(foo3 => ()) };
    like $@, qr/No hooks registered for foo3/;
  
  };
  
  subtest 'command list hook' => sub {
  
    $meta->register_hook(
      foo4 => [[$^X, -e => 'print @ARGV', 'hello', ' ', 'world']],
    );
    
    my $out = capture_merged { $build->_call_hook('foo4') };
    note $out;
    
    like $out, qr/hello world/s;
  
  };
  
  subtest 'command with failure' => sub {
  
    $meta->register_hook(
      foo5 => [[$^X, -e => 'exit 1']],
    );
    
    my $error;
    note capture_merged {
      eval { $build->_call_hook('foo5') };
      $error = $@;
    };
    
    like $error, qr/external command failed/;
  
  };
  
  subtest 'command with failure, followed by good command' => sub {
  
    $meta->register_hook(
      foo5 => [[$^X, -e => '']],
    );
    
    note capture_merged {
      $build->_call_hook('foo5');
    };
    
    ok 1;
  
  };

};

subtest 'probe' => sub {

  subtest 'system' => sub {
  
    my($build, $meta) = build_blank_alien_build;
    
    $meta->register_hook(
      probe => sub {
        note "dir = $CWD";
        return 'system';
      },
    );
    
    is($build->probe, 'system');
    is($build->runtime_prop->{install_type}, 'system');
  
  };
  
  subtest 'share' => sub {

    my($build, $meta) = build_blank_alien_build;
    
    $meta->register_hook(
      probe => sub {
        note "dir = $CWD";
        return 'system';
      },
    );
    
    is($build->probe, 'system');
    is($build->runtime_prop->{install_type}, 'system');
  
  };
  
  subtest 'throw exception' => sub {
  
    my($build, $meta) = build_blank_alien_build;
    
    $meta->register_hook(
      probe => sub {
        note "dir = $CWD";
        die "error will robinson!";
      },
    );
    
    my $type;
    note capture_merged { $type = $build->probe };
    is($type, 'share');
    is($build->runtime_prop->{install_type}, 'share');
  
  };
  
  subtest 'env' => sub {
  
    foreach my $expected (qw( share system ))
    {
    
      subtest "type = $expected" => sub {
        
        local $ENV{ALIEN_INSTALL_TYPE} = $expected;
        
        my($build, $meta) = build_blank_alien_build;
        
        $meta->register_hook(
          probe => sub {
            die "should not get into here!";
          },
        );
        
        is( $build->probe, $expected);
        
      };
    
    }
  
  };
  
};

subtest 'gather system' => sub {

  local $ENV{ALIEN_INSTALL_TYPE} = 'system';

  my($build, $meta) = build_blank_alien_build;
  
  $meta->register_hook(
    gather_system => sub {
      my($build) = @_;
      $build->runtime_prop->{cflags}  = '-DFoo=1';
      $build->runtime_prop->{libs}    = '-lfoo';
      $build->runtime_prop->{version} = '1.2.3';
    },
  );
  
  if($build->install_type eq 'system')
  {
    $build->gather_system;
  }
  
  is(
    $build->runtime_prop,
    hash {
      field cflags  => '-DFoo=1';
      field libs    => '-lfoo';
      field version => '1.2.3';
      etc;
    },
    'runtime props'
  );
  
  is(
    $build->install_prop,
    hash {
      field finished => T();
      field complete => hash {
        field gather_system => T();
        etc;
      };
      etc;
    },
    'install props'
  );

};

subtest 'download' => sub {

  my $build = sub {
    my($build, $meta) = build_blank_alien_build;
    require Alien::Build::Plugin::Fetch::Corpus;
    my $plugin = Alien::Build::Plugin::Fetch::Corpus->new(@_);
    $plugin->init($meta);
    ($build, $meta, $plugin);
  };

  my $tarpath = path('corpus/dist/foo-1.00.tar.gz')->absolute;

  my $check = sub {
    my($build) = @_;

    note scalar capture_merged { $build->download };
     
    is(
      $build->install_prop,
      hash {
        field download => match qr/foo-1.00.tar.gz/;
        field complete => hash {
          field download => T();
          etc;
        };
        etc;
      },
      'install props'
    );
      
    note "build.install_prop.download=@{[ $build->install_prop->{download} ]}";
        
    is(
      path($build->install_prop->{download})->slurp_raw,
      $tarpath->slurp_raw,
      'file matches',
    );
  };  

  subtest 'component' => sub {

    foreach my $file_as (qw( content path ))
    {
  
      subtest "single download with file as $file_as" => sub {
    
        my($build, $meta) = $build->(
          url            => 'http://test1.test/foo/bar/baz/foo-1.00.tar.gz',
          return_file_as => $file_as,
        );
      
        $check->($build);
    
      };
    }
    
    foreach my $listing_as (qw( list html dir_listing ))
    {
    
      subtest "listing download with listing as $listing_as" => sub {
      
        my($build, $meta) = $build->(
          url               => 'http://test1.test/foo/bar/baz/',
          return_listing_as => $listing_as,
        );
        
        $check->($build);
      
      };
    
    }
  
  };
  
  subtest 'command single' => sub {
  
    my $guard = system_fake
      wget => sub {
        my($url) = @_;
        
        # just pretend that we have some hidden files
        path('.foo')->touch;
        
        if($url eq 'http://test1.test/foo/bar/baz/foo-1.00.tar.gz')
        {
          print "200 found $url!\n";
          path('foo-1.00.tar.gz')->spew_raw($tarpath->slurp_raw);
          return 0;
        }
        else
        {
          print "404 not found $url\n";
          return 2;
        }
      };
    
    my($build, $meta) = build_blank_alien_build;
    
    $meta->register_hook(
      download => [ "wget http://test1.test/foo/bar/baz/foo-1.00.tar.gz" ],
    );
    
    $check->($build);
  
  };
  
  subtest 'command no file' => sub {
  
    my $guard = system_fake
      true => sub {
        0;
      };
    
    my($build, $meta) = build_blank_alien_build;
    
    $meta->register_hook(
      download => [ 'true' ],
    );
    
    my($out, $error) = capture_merged { eval { $build->download }; $@ };
    note $out;
    like $error, qr/no files downloaded/, 'diagnostic failure';
  
  };
  
  subtest 'command multiple files' => sub {
  
    my $guard = system_fake
      explode => sub {
        path($_)->touch for map { "$_.txt" } qw( foo bar baz );
        0;
      };
    
    my($build, $meta) = build_blank_alien_build;
    
    $meta->register_hook(
      download => ['explode'],
    );
    
    note scalar capture_merged { $build->download };
    
    is(
      $build->install_prop,
      hash {
        field extract => T();
        field complete => hash {
          field download => T();
          field extract  => T();
          etc;
        };
        etc;
      },
      'install props'
    );
    
    my $dir = path($build->install_prop->{extract});
    ok(-d $dir, "dir exists");
    ok(-f $dir->child($_), "file $_ exists") for map { "$_.txt" } qw( foo bar baz );
  
  };
  
};

done_testing;

{
  package MyBuild;
  use base 'Alien::Build';
}

