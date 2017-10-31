use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use lib 't/lib';
use lib 'corpus/lib';
use MyTest::System;
use Alien::Build;
use Capture::Tiny qw( capture_merged );
use File::chdir;
use Path::Tiny qw( path );
use Alien::Build::Util qw( _dump );

subtest 'simple new' => sub {

  subtest 'basic basic' => sub {
    my $build = MyBuild->new;
    isa_ok $build, 'Alien::Build';
    isa_ok( $build->meta, 'Alien::Build::Meta' );
    isa_ok( MyBuild->meta, 'Alien::Build::Meta' );
    note(_dump $build->meta);
  };
  
  subtest 'with meta_prop in new' => sub {
    my $build = MyBuild2->new(meta_prop => { roger => 1, ramjet => [ 1,2,3] });
    note(_dump $build->meta->prop);
    is(
      $build->meta_prop,
      hash {
        field roger => 1;
        field ramjet => [1,2,3];
        etc;
      },
      'has argument properties',
    );
  };

};

subtest 'from file' => sub {

  my $build = Alien::Build->load('corpus/basic/alienfile');
  
  isa_ok $build, 'Alien::Build';

  isa_ok( $build->meta, 'Alien::Build::Meta' );

  note(_dump $build->meta);

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

  subtest 'basic' => sub {

    my $build = alienfile q{ use alienfile };
    my $meta = $build->meta;
  
    note(_dump $meta);
  
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
};

subtest 'hook' => sub {

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  subtest 'simple single working hook' => sub {
  
    my @foo1;
    my $props;
  
    $meta->register_hook(
      foo1 => sub {
        @foo1 = @_;
        my($build) = @_;
        $props = $build->hook_prop;
        return 42;
      }
    );
  
    is( $build->hook_prop, undef );  
  
    is( $build->_call_hook(foo1 => ('roger', 'ramjet')), 42);

    is(
      $props,
      hash {
        field name => 'foo1';
        etc;
      },
    );

    is( $build->hook_prop, undef );  

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
  
  subtest 'around hook' => sub {
  
    subtest 'single wrapper' => sub {
    
      my @args;
    
      $meta->register_hook(
        foo6 => sub {
          my $build = shift;
          @args = @_;
          die "oops" unless $build->isa('Alien::Build');
          return 'platypus';
        },
      );
      
      $meta->around_hook(
        foo6 => sub {
          my $orig = shift;
          return $orig->(@_) . ' man';
        }
      );
      
      is( $build->_call_hook('foo6', 1, 2), 'platypus man', 'return value' );
      is( \@args, [1,2], 'arguments' );
    
    };
    
    subtest 'double wrapper' => sub {
    
      my @args;
    
      $meta->register_hook(
        foo7 => sub {
          my $build = shift;
          @args = @_;
          die "oops" unless $build->isa('Alien::Build');
          return 'platypus';
        },
      );
      
      $meta->around_hook(
        foo7 => sub {
          my $orig = shift;
          return '(' . $orig->(@_) . ') man';
        }
      );
      
      $meta->around_hook(
        foo7 => sub {
          my $orig = shift;
          return 'the (' . $orig->(@_) . ')';
        }
      );
      
      is( $build->_call_hook('foo7', 1, 2), 'the ((platypus) man)', 'return value' );
      is( \@args, [1,2], 'arguments' );
    
    };
    
    subtest 'alter args' => sub {
    
      my @args;
      
      $meta->register_hook(
        foo8 => sub {
          my $build = shift;
          @args = @_;
          die "oops" unless $build->isa('Alien::Build');
          return 'platypus';
        },
      );
      
      $meta->around_hook(
        foo8 => sub {
          my $orig = shift;
          my $build = shift;
          $orig->($build, map { $_ + 1 } @_);
        }
      );
      
      is( $build->_call_hook('foo8', 1, 2), 'platypus' );
      is( \@args, [ 2,3 ] );
    
    };
  
  };

};

subtest 'probe' => sub {

  subtest 'system' => sub {
  
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    
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

    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    
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
  
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    
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
  
};

subtest 'gather system' => sub {

  local $ENV{ALIEN_INSTALL_TYPE} = 'system';

  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  $meta->register_hook(
    probe => sub {
      'system';
    }
  );
  
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
    note capture_merged {
      $build->build;
    };
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
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
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
    
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    
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
    
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    
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
    
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
    
    $meta->register_hook(
      download => ['explode'],
    );
    
    note scalar capture_merged { $build->download };
    
    is(
      $build->install_prop,
      hash {
        field download => T();
        field complete => hash {
          field download => T();
          etc;
        };
        etc;
      },
      'install props'
    );
    
    my $dir = path($build->install_prop->{download});
    ok(-d $dir, "dir exists");
    ok(-f $dir->child($_), "file $_ exists") for map { "$_.txt" } qw( foo bar baz );
  
  };
  
};

alien_subtest 'extract' => sub {

  my $tar_cmd = do {
    require Alien::Build::Plugin::Extract::CommandLine;
    my $plugin = Alien::Build::Plugin::Extract::CommandLine->new;
    $plugin->tar_cmd;
  };
  
  skip_all 'test requires command line tar' unless $tar_cmd;

  my $build = alienfile_ok q{
    use alienfile;
  };
  my $meta = $build->meta;
  
  $meta->register_hook(
    extract => [ [ $tar_cmd, "xf", "%{alien.install.download}"] ],
  );
  
  $build->install_prop->{download} = path("corpus/dist/foo-1.00.tar")->absolute->stringify;
  
  my($out, $dir, $error) = capture_merged { (eval { $build->extract }, $@) };
  
  note $out if $out ne '';
  
  is $error, '', 'no exception';
  note $error if $error;
  ok defined $dir && -d $dir, 'directory exists';
  note "dir = $dir";

  foreach my $name (qw( configure foo.c ))
  {
    my $file = path($dir)->child($name);
    ok -f $file, "$name exists";
  }
  
  my $extract = $build->install_prop->{extract};
  
  note "build.install.extract = $extract";
  ok( -d $extract, "build.install.extract is a directory" );
  ok( -f "$extract/configure", "has configure" );
  ok( -f "$extract/foo.c", "has foo.c" );
};

subtest 'build' => sub {

  subtest 'plain' => sub {
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
  
    my @data;
  
    $meta->prop->{env}->{FOO1} = 'bar1';
    $build->install_prop->{env}->{FOO3} = 'bar3';

    local $ENV{FOO2} = 'bar2';
  
    $meta->register_hook(
      probe => sub { 'share' },
    );
  
    $meta->register_hook(
      extract => sub {
        path('file1')->spew('text1');
        path('file2')->spew('text2');
      },
    );
  
    $meta->register_hook(
      build => sub {
        is $ENV{FOO1}, 'bar1';
        is $ENV{FOO2}, 'bar2';
        is $ENV{FOO3}, 'bar3';
        @data = (path('file1')->slurp, path('file2')->slurp);
      },
    );
    
    my $gather = 0;
    
    $meta->register_hook(
      gather_share => sub {
        $gather = 1;
      },
    );
    
    my $tmp = Path::Tiny->tempdir;
    my $share = $tmp->child('blib/lib/auto/share/Alien-Foo/');
    $build->install_prop->{download} = path("corpus/dist/foo-1.00.tar")->absolute->stringify;
    $build->set_stage($share->stringify);

    note capture_merged {
      $build->build;
      ();
    };
  
    is(
      \@data,
      [ 'text1', 'text2'],
      'build',
    );
    
    is $gather, 1, 'ran gather';
    
    ok( -f $share->child('_alien/alien.json'), 'has alien.json');
    #ok( -f $share->child('_alienfile'), 'has alienfile');
  };
  
  subtest 'destdir' => sub {
  
    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;
  
    $meta->register_hook(
      probe => sub { 'share' },
    );

    $meta->register_hook(
      extract => sub {
        path('file1')->spew('text1');
        path('file2')->spew('text2');
      },
    );
    
    $meta->register_hook(
      build => sub {
        my($build) = @_;
        my $prefix = $build->install_prop->{prefix};

        # Handle DESTDIR in windows, where : may be
        # in install.prefix
        $prefix =~ s!^([a-z]):!$1!i if $^O eq 'MSWin32';

        my $dir = path("$ENV{DESTDIR}/$prefix");
        note "install dir = $dir";
        $dir->mkpath;
        $dir->child($_)->mkpath for qw( bin lib );
        $dir->child('bin/foo')->spew('foo exe');
        $dir->child('lib/libfoo.a')->spew('foo lib');
      },
    );
    
    my $gather = 0;
    
    $meta->register_hook(
      gather_share => sub {
        $gather = 1;
      },
    );
    
    my $tmp = Path::Tiny->tempdir;
   
    my $share = $tmp->child('blib/lib/auto/share/Alien-Foo/');

    $build->meta_prop->{destdir}       = 1;
    $build->install_prop->{download}   = path("corpus/dist/foo-1.00.tar")->absolute->stringify;
    $build->set_prefix($tmp->child('usr/local')->stringify);
    $build->set_stage($share->stringify);
    
    note capture_merged { $build->build };
  
    ok(-d $share, "directory created" );
    
    is $gather, 1, 'ran gather';
    
    ok( -f $share->child('_alien/alien.json'), 'has alien.json');
    ok( -f $share->child('_alien/alienfile'), 'has alienfile');
  
  };
  
};

subtest 'checkpoint' => sub {

  my $root = Path::Tiny->tempdir;

  my $alienfile = Path::Tiny->tempfile( TEMPLATE => 'alienfileXXXXXXX' );
  $alienfile->spew(q{
    use alienfile;
    meta_prop->{foo1} = 'bar1';
  });
  
  subtest 'create checkpoint' => sub {
  
    my $build = Alien::Build->load("$alienfile", root => "$root");
    is($build->meta_prop->{foo1}, 'bar1');
    $build->install_prop->{foo2} = 'bar2';
    $build->runtime_prop->{foo3} = 'bar3';
    $build->checkpoint;
    
    ok( -r path($build->root, 'state.json') );
  
  };
  
  subtest 'resume checkpoint' => sub {
  
    my $build = Alien::Build->resume("$alienfile", "$root");
    is($build->meta_prop->{foo1}, 'bar1');
    is($build->install_prop->{foo2}, 'bar2');
    is($build->runtime_prop->{foo3}, 'bar3');
  
  };

};

subtest 'patch' => sub {

  subtest 'single' => sub {

    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;

    my $tmp = Path::Tiny->tempdir;
    my $share = $tmp->child('blib/lib/auto/share/Alien-Foo/');
    $build->install_prop->{download} = path("corpus/dist/foo-1.00.tar")->absolute->stringify;
    $build->install_prop->{stage}    = $share->stringify;
  
    $meta->register_hook(
      probe => sub { 'share' },
    );
  
    $meta->register_hook(
      extract => sub {
        path('file1')->spew('The quick brown dog jumps over the lazy dog');
        path('file2')->spew('text2');
      },
    );
  
    $meta->register_hook(
      patch => sub {
        # fix the saying.
        path('file1')->edit(sub { s/dog/fox/ });
      },
    );
  
    $meta->register_hook(
      build => sub {
        my($build) = @_;
        path('file1')->copy(path($build->install_prop->{stage})->child('file3'));
      },
    );
  
    note capture_merged {
      $build->build;
      ();
    };
  
    my $file3 = path($build->install_prop->{stage})->child('file3');
    is(
      $file3->slurp,
      'The quick brown fox jumps over the lazy dog',
    );
  };

  subtest 'double' => sub {

    my $build = alienfile filename => 'corpus/blank/alienfile';
    my $meta = $build->meta;

    my $tmp = Path::Tiny->tempdir;
    my $share = $tmp->child('blib/lib/auto/share/Alien-Foo/');
    $build->install_prop->{download} = path("corpus/dist/foo-1.00.tar")->absolute->stringify;
    $build->install_prop->{stage}    = $share->stringify;
  
    $meta->register_hook(
      probe => sub { 'share' },
    );
  
    $meta->register_hook(
      extract => sub {
        path('file1')->spew('The quick brown dog jumps over the lazy dog');
        path('file2')->spew('The quick brown fox jumps over the lazy fox');
      },
    );
  
    $meta->register_hook(
      patch => sub {
        # fix the saying.
        path('file1')->edit(sub { s/dog/fox/ });
      },
    );
    
    $meta->register_hook(
      patch => sub {
        # fix the saying.
        path('file2')->edit(sub { s/fox$/dog/ });
      },
    );
  
    $meta->register_hook(
      build => sub {
        my($build) = @_;
        path('file1')->copy(path($build->install_prop->{stage})->child('file3'));
        path('file2')->copy(path($build->install_prop->{stage})->child('file4'));
      },
    );
  
    note capture_merged {
      $build->build;
      ();
    };
  
    my $file3 = path($build->install_prop->{stage})->child('file3');
    is(
      $file3->slurp,
      'The quick brown fox jumps over the lazy dog',
    );

    my $file4 = path($build->install_prop->{stage})->child('file4');
    is(
      $file4->slurp,
      'The quick brown fox jumps over the lazy dog',
    );
  };

};

subtest 'preload' => sub {

  { package Alien::Build::Plugin::Preload1;
    $INC{'Alien/Build/Plugin/Preload1.pm'} = __FILE__;
    use Alien::Build::Plugin;
    sub init
    {
      my($self, $meta) = @_;
      $meta->register_hook('preload1' => sub {});
    }
  }
  { package Alien::Build::Plugin::Preload1::Preload2;
    $INC{'Alien/Build/Plugin/Preload1/Preload2.pm'} = __FILE__;
    use Alien::Build::Plugin;
    sub init
    {
      my($self, $meta) = @_;
      $meta->register_hook('preload2' => sub {});
    }
  }
  
  local $ENV{ALIEN_BUILD_PRELOAD} = join ';', qw( Preload1 Preload1::Preload2 );
  
  my $build = alienfile filename => 'corpus/blank/alienfile';
  my $meta = $build->meta;
  
  ok( $meta->has_hook($_), "has hook $_" ) for qw( preload1 preload2 );

};

subtest 'first probe returns share' => sub {

  subtest 'share, system' => sub {

    my $build = alienfile q{
      use alienfile;
      probe sub { 'share' };
      probe sub { 'system' };
    };
  
    note capture_merged {
      $build->probe;
    };
  
    is( $build->install_type, 'system' );
  };
  
  subtest 'command ok' => sub {
  
    my $guard = system_fake
      'pkg-config' => sub { 0 }
    ;
  
    my $build = alienfile q{
      use alienfile;
      probe [ [ 'pkg-config', '--exists', 'libfoo' ] ];
    };
    
    note capture_merged {
      $build->probe;
      ();
    };
    
    is($build->install_type, 'system');
  
  };

  subtest 'command bad' => sub {
  
    my $guard = system_fake
      'pkg-config' => sub { 1 }
    ;
  
    my $build = alienfile q{
      use alienfile;
      probe [ [ 'pkg-config', '--exists', 'libfoo' ] ];
    };
    
    note capture_merged {
      $build->probe;
      ();
    };
    
    is($build->install_type, 'share');
  
  };

};

alien_subtest 'system' => sub {

  my @args;

  my $guard = system_fake
    frooble => sub {
      @args = ('frooble', @_);
    },
    xor => sub {
      @args = ('xor', @_);
    },
  ;

  my $build = alienfile_ok q{
    use alienfile;
  };
  
  $build->meta->interpolator->add_helper(
    foo => sub { '1234' },
  );

  $build->meta->interpolator->add_helper(
    bar => sub { 'xor' },
  );
  
  note scalar capture_merged { $build->system('frooble', '%{foo}') };
  
  is(
    \@args,
    [ 'frooble', '1234' ],
  );
  
  note scalar capture_merged { $build->system('%{bar}') };
  
  is(
    \@args,
    [ 'xor' ],
  );

};

subtest 'requires pulls helpers' => sub {

  my $build = alienfile q{
    use alienfile;
    requires 'Alien::libfoo1';
    probe sub { 'system' }
  };

  $build->load_requires('any');
  ok($build->meta->interpolator->has_helper('foo1'), 'has helper foo1');
  ok($build->meta->interpolator->has_helper('foo2'), 'has helper foo2');

};

alien_subtest 'around bug?' => sub {

  my $build = alienfile_ok q{
  
    use alienfile;
    
    meta->register_hook(
      foo => sub {
        my($build, $arg) = @_;
        return scalar reverse $arg;
      },
    );
  
  };
  
  is $build->_call_hook(foo => 'bar'), 'rab';

  $build->meta->around_hook(
    foo => sub {
      my($orig, $build, $arg) = @_;
      $orig->($build, "a${arg}b");
    },
  );
  
  is $build->_call_hook(foo => 'bar'), 'braba';

  $build->meta->around_hook(
    foo => sub {
      my($orig, $build, $arg) = @_;
      $orig->($build, "|${arg}|");
    },
  );
  
  is $build->_call_hook(foo => 'bar'), 'b|rab|a';

};

subtest 'requires of Alien::Build or Alien::Base' => sub {

  alien_subtest 'Alien::Build' => sub {
  
    my $build = alienfile_ok q{
      use alienfile;
      requires 'Alien::Build' => 0;
    };
    
    eval {
      $build->load_requires('configure');
      $build->load_requires('share');
    };
    
    is $@, '';
    
  };

  alien_subtest 'Alien::Base' => sub {
  
    my $build = alienfile_ok q{
      use alienfile;
      requires 'Alien::Base' => 0;
    };
    
    eval {
      $build->load_requires('configure');
      $build->load_requires('share');
    };
    
    is $@, '';
    
  };

};

subtest 'out-of-source build' => sub {

  local $Alien::Build::VERSION = '1.08';

  alien_subtest 'basic' => sub {
  
    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );

      meta->prop->{out_of_source} = 1;
      plugin 'Download::Foo';

      share {
        build sub {
          my($build) = @_;
          my $extract = $build->install_prop->{extract};
          
          die 'no extract'             unless -d $extract;
          die 'no $extract/configure'  unless -f "$extract/configure";
          die 'no $extract/foo.c'      unless -f "$extract/foo.c";
          
          die 'found $build/configure' if -f 'configure';
          die 'found $build/foo.c'     if -f 'foo.c';
        };
      };
    };
    
    alien_build_ok;
  
  };
  
  alien_subtest 'from bundled source' => sub {

    local $Alien::Build::Plugin::Fetch::LocalDir::VERSION = '1.07';
  
    my $build = alienfile_ok q{
      use alienfile;
      
      meta->prop->{out_of_source} = 1;
      meta->prop->{start_url}     = 'corpus/dist/foo-1.00';
      
      share {
        plugin 'Fetch::LocalDir';
        plugin 'Extract' => 'd';
        build sub {
          my($build) = @_;
          my $extract = $build->install_prop->{extract};
          
          die 'no extract'             unless -d $extract;
          die 'no $extract/configure'  unless -f "$extract/configure";
          die 'no $extract/foo.c'      unless -f "$extract/foo.c";
          
          die 'found $build/configure' if -f 'configure';
          die 'found $build/foo.c'     if -f 'foo.c';
        };
      };
    };
    
    alien_build_ok;
    
    my $extract = $build->install_prop->{extract};
    note "extract = $extract";
  
  };

};

subtest 'test' => sub {

  local $Alien::Build::VERSION = $Alien::Build::VERSION;
  $Alien::Build::VERSION ||= '1.14';
  

  alien_subtest 'good' => sub {
  
    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      
      probe sub { 'share' };
      
      share {
        download sub { path('file1')->touch };
        extract sub { path($_)->touch for qw( file2 file3 ) };
        build sub {
          log("the build");
          path('file4')->spew('content of file4')
        };
        test sub {
          log("the test");
          my $x = path('file4')->slurp;
          die "hrm" unless $x eq 'content of file4';
        };
      };
    
    };
    
    alien_install_type_is 'share';
    alien_checkpoint_ok;
    alien_resume_ok;
    alien_build_ok;
    alien_checkpoint_ok;

    my $build = alien_resume_ok;
    
    my($out, $error) = capture_merged {
      eval { $build->test };
      $@;
    };
    note $out;
    
    is $error, '';
  };
  
  alien_subtest 'bad' => sub {

    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      
      probe sub { 'share' };
      
      share {
        download sub { path('file1')->touch };
        extract sub { path($_)->touch for qw( file2 file3 ) };
        build sub { };
        test sub {
          log("the test");
          die "bogus!";
        };
      };
    
    };
    
    alien_install_type_is 'share';
    alien_checkpoint_ok;
    alien_resume_ok;
    alien_build_ok;
    alien_checkpoint_ok;

    my $build = alien_resume_ok;

    my($out, $error) = capture_merged {
      eval { $build->test };
      $@;
    };
    note $out;
    
    like $error, qr/bogus!/;
  };
  
  alien_subtest 'ffi' => sub {

    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      
      probe sub { 'share' };
      
      share {
        download sub { path('file1')->touch };
        extract sub { path($_)->touch for qw( file2 file3 ) };
        build sub {
          log("the build");
          path('file4')->spew('content of file4')
        };
        ffi {
        
          build sub {
            path('file5')->spew('content of file5');
          };
          
          test sub {
            die "bogus1" unless -f "file2";
            die "bogus2" unless -f "file3";
            my $x = path("file5")->slurp;
            die "bogus3" unless $x eq 'content of file5';
          };
        
        };
      };
    
    };
    
    alien_install_type_is 'share';
    alien_checkpoint_ok;
    alien_resume_ok;
    alien_build_ok;
    alien_checkpoint_ok;

    my $build = alien_resume_ok;

    my($out, $error) = capture_merged {
      eval { $build->test };
      $@;
    };
    note $out;
    
    is $error, '';
  };

  alien_subtest 'bad ffi' => sub {

    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      
      probe sub { 'share' };
      
      share {
        download sub { path('file1')->touch };
        extract sub { path($_)->touch for qw( file2 file3 ) };
        build sub {
          log("the build");
          path('file4')->spew('content of file4')
        };
        ffi {
        
          build sub {
            path('file5')->spew('content of file5');
          };
          
          test sub {
            die "bogus4";
          };
        
        };
      };
    
    };
    
    alien_install_type_is 'share';
    alien_checkpoint_ok;
    alien_resume_ok;
    alien_build_ok;
    alien_checkpoint_ok;

    my $build = alien_resume_ok;

    my($out, $error) = capture_merged {
      eval { $build->test };
      $@;
    };
    note $out;
    
    like $error, qr/bogus4/;
  };
  
  alien_subtest 'system good' => sub {
  
    alienfile_ok q{
      use alienfile;
      probe sub { 'system' };
      sys {
        test sub {
          my($build) = @_;
          log('in test!');
          $build->install_prop->{foobar} = 'baz';
        };
      };
    };
    
    alien_install_type_is 'system';
    alien_checkpoint_ok;
    alien_resume_ok;
    alien_build_ok;
    alien_checkpoint_ok;

    my $build = alien_resume_ok;
    my($out, $error) = capture_merged {
      eval { $build->test };
      $@;
    };
    note $out;
    
    is $error, '';
    
    is($build->install_prop->{foobar}, 'baz');
    
  };
  
  alien_subtest 'system bad' => sub {

    alienfile_ok q{
      use alienfile;
      probe sub { 'system' };
      sys {
        test sub {
          my($build) = @_;
          log('in test!');
          $build->install_prop->{foobar} = 'baz2';
          die "bogus16";
        };
      };
    };
    
    alien_install_type_is 'system';
    alien_checkpoint_ok;
    alien_resume_ok;
    alien_build_ok;
    alien_checkpoint_ok;

    my $build = alien_resume_ok;
    my($out, $error) = capture_merged {
      eval { $build->test };
      $@;
    };
    note $out;
    
    like $error, qr/bogus16/;
    
    is($build->install_prop->{foobar}, 'baz2');
  };

};

alien_subtest 'pkg-config path during build' => sub {

  my $build = alienfile_ok q{
  
    use alienfile;
    use Path::Tiny qw( path );
    use Env qw( @PKG_CONFIG_PATH );
  
    probe sub { 'share' };
  
    share {
    
      requires 'Alien::libfoo2';
      download sub { path('file1')->touch };
      extract sub { path('file2')->touch };
      build sub {
        my($build) = @_;
        $build->runtime_prop->{my_pkg_config_path} = [@PKG_CONFIG_PATH];
      };
    
    };
  
  };

  alien_build_ok;

  is(
    $build->runtime_prop,
    hash {
      field my_pkg_config_path => array {
        item validator(sub {
          return -f "$_/x1.pc";
        });
        item validator(sub {
          return -f "$_/x2.pc";
        });
        end;
      };
      etc;
    },
    'has arch and arch-indy pkg-config paths',
  );
  
};

subtest 'network available' => sub {

  alien_subtest 'default' => sub {
    my $build = alienfile_ok q{ use alienfile };
    is($build->meta_prop->{network}, T());
  };  

  alien_subtest 'override' => sub {
    my $build = alienfile_ok q{ use alienfile; meta->prop->{network} = 0 };
    is($build->meta_prop->{network}, F());
  };
  
  alien_subtest 'NO_NETWORK_TESTING' => sub {
    local $ENV{NO_NETWORK_TESTING} = 1;
    my $build = alienfile_ok q{ use alienfile };
    is($build->meta_prop->{network}, F());
  };

  alien_subtest 'ALIEN_INSTALL_NETWORK=1' => sub {
    local $ENV{ALIEN_INSTALL_NETWORK} = 1;
    my $build = alienfile_ok q{ use alienfile };
    is($build->meta_prop->{network}, T());
  };

  alien_subtest 'ALIEN_INSTALL_NETWORK=0' => sub {
    local $ENV{ALIEN_INSTALL_NETWORK} = 0;
    my $build = alienfile_ok q{ use alienfile };
    is($build->meta_prop->{network}, F());
  };

};

subtest 'local_source' => sub {

  alien_subtest 'start_url undefined' => sub {
    my $build = alienfile_ok q{ use alienfile };
    is($build->meta_prop->{local_source}, F());
  };

  alien_subtest 'start_url undefined override' => sub {
    my $build = alienfile_ok q{ use alienfile; meta->prop->{local_source} = 1; };
    is($build->meta_prop->{local_source}, T());
  };

  alien_subtest 'start_url = foo/bar/baz' => sub {
    my $build = alienfile_ok q{ use alienfile; share { start_url 'foo/bar/baz' } };
    is($build->meta_prop->{local_source}, T());
  };

  alien_subtest 'start_url = C:/foo/bar/baz' => sub {
    my $build = alienfile_ok q{ use alienfile; share { start_url 'C:/foo/bar/baz' } };
    is($build->meta_prop->{local_source}, T());
  };

  alien_subtest 'start_url = /foo/bar/baz' => sub {
    my $build = alienfile_ok q{ use alienfile; share { start_url '/foo/bar/baz' } };
    is($build->meta_prop->{local_source}, T());
  };

  alien_subtest 'start_url = ./foo/bar/baz' => sub {
    my $build = alienfile_ok q{ use alienfile; share { start_url './foo/bar/baz' } };
    is($build->meta_prop->{local_source}, T());
  };

  alien_subtest 'start_url = http://foo.example/foo/bar/baz' => sub {
    my $build = alienfile_ok q{ use alienfile; share { start_url 'http://foo.example/foo/bar/baz' } };
    is($build->meta_prop->{local_source}, F());
  };

  alien_subtest 'start_url = http://foo.example/foo/bar/baz override' => sub {
    my $build = alienfile_ok q{ use alienfile; share { start_url 'http://foo.example/foo/bar/baz'; meta->prop->{local_source} = 1; } };
    is($build->meta_prop->{local_source}, T());
  };

};

subtest 'do not allow network install' => sub {

  alien_subtest 'share' => sub {

    my $build = alienfile_ok q{ use alienfile; probe sub { 'share'}; meta->prop->{network} = 0; meta->prop->{local_source} = 0; };

    my($out, $err) = capture_merged {
      eval {
        $build->probe;
      };
      $@;
    };
  
    note $out;
  
    like $err, qr/network fetch is turned off/;
    
  };

  alien_subtest 'system' => sub {
    my $build = alienfile_ok q{ use alienfile; probe sub { 'system'}; meta->prop->{network} = 0; meta->prop->{local_source} = 0; };
    alien_install_type_is 'system';
  };
  
};

done_testing;

{
  package MyBuild;
  use base 'Alien::Build';
}

{
  package MyBuild2;
  use base 'Alien::Build';
}

