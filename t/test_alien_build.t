use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );

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
      share {
        plugin 'Test::Mock',
          probe    => 'share',
          download => 1,
          extract  => 1,
          build    => 1;
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

    ok -f path($prefix)->child('lib/libfoo.a');
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

subtest 'alien_download_ok' => sub {

  subtest 'good download' => sub {

    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        download sub {
          path('file1')->spew("xx\n");
        };
      };
    };

    my $file = alien_download_ok;

    is(
      path($file)->slurp,
      "xx\n",
      'file content matches',
    );

  };

  subtest 'good download' => sub {

    alienfile_ok q{
      use alienfile;
      probe sub { 'share' };
      share {
        download sub {
        };
      };
    };

    my $file;

    is(
      intercept { $file = alien_download_ok },
      array {
        event Ok => sub {
          call pass => F();
        };
        etc;
      },
      'test fails',
    );

    is($file, U(), 'return value is undef');

  };

};

subtest 'alien_extract_ok' => sub {

  subtest 'good extract' => sub {

    alienfile_ok q{
      use alienfile;
      use Path::Tiny qw( path );
      probe sub { 'share' };
      share {
        plugin 'Test::Mock',
          download => 1,
          extract  => { file2 => '', file3 => '' };
      };
    };

    my $dir = alien_extract_ok;

    is(-d $dir, T(), "dir is dir" );
    is(-f path("$dir/file2"), T(), "has file2" );
    is(-f path("$dir/file3"), T(), "has file3" );

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

    my $dir;
    is(
      intercept { $dir = alien_extract_ok },
      array {
        event Ok => sub {
          call pass => F();
        };
        etc;
      },
      'test fails',
    );

    is( $dir, U(), "dir is undef");
  };

};

subtest 'alien_rc' => sub {

  subtest 'create rc' => sub {

    alien_rc q{

      preload 'Foo::Bar';

      package Alien::Build::Plugin::Foo::Bar;

      use Alien::Build::Plugin;

      sub init
      {
        my($self, $meta) = @_;
        $meta->prop->{x} = 'y';
      }

    };

    note path($ENV{ALIEN_BUILD_RC})->slurp;

    my $build = alienfile_ok q{ use alienfile };

    is(
      $build->meta_prop->{x}, 'y',
    );
  };

};

subtest 'test for custom subtest' => sub {

  subtest 'basic pass' => sub {

    my $ok;

    my $events = intercept {
      $ok = alien_subtest 'foo' => sub {
        ok 1;
      };
    };

    is(
      $events,
      array {
        event Subtest => sub {
          call pass => T();
          call name => 'foo';
          call buffered => T();
          call subevents => array {
            etc;
          };
        };
        end;
      },
    );

    is(
      $ok,
      T(),
    );

  };

  subtest 'basic fail' => sub {

    my $ok;

    my $events = intercept {
      $ok = alien_subtest 'foo' => sub {
        ok 0;
      };
    };

    is(
      $events,
      array {
        event Subtest => sub {
          call pass => F();
          call name => 'foo';
          call buffered => T();
          call subevents => array {
            etc;
          };
        };
        event Diag => sub {};
        end;
      },
    );

    is(
      $ok,
      F(),
    );

  };

};

subtest 'alien_checkpoint_ok' => sub {

  alien_subtest 'without build' => sub {

    is(
      intercept { alien_checkpoint_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => "alien checkpoint ok";
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'no build to checkpoint';
        };
        end;
      },
    );

  };

  alien_subtest 'with failure in checkpont' => sub {

    alienfile_ok q{ use alienfile };

    my $mock = mock 'Alien::Build' => (
      override => [
        checkpoint => sub {
          die 'some error in checkpoint';
        },
      ],
    );

    is(
      intercept { alien_checkpoint_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => "alien checkpoint ok";
        };
        event Diag => sub {};
        event Diag => sub {
          call message => match qr/error in checkpoint: some error in checkpoint/
        };
        end;
      },
    );

  };

  alien_subtest 'with goodness and light' => sub {

    alienfile_ok q{ use alienfile };

    is(
      intercept { alien_checkpoint_ok },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'alien checkpoint ok';
        };
        end;
      },
    );

  };

};

subtest 'alien_resume_ok' => sub {

  alien_subtest 'with no build' => sub {

    is(
      intercept { alien_resume_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'alien resume ok';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'no build to resume';
        };
        end;
      },
    );

  };

  subtest 'without checkpoint' => sub {

    alienfile_ok q{ use alienfile };

    is(
      intercept { alien_resume_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'alien resume ok';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => 'build has not been checkpointed';
        };
        end;
      },
    );

  };

  subtest 'die in resume' => sub {

    alienfile_ok q{ use alienfile };

    my $mock = mock 'Alien::Build' => (
      override => [
        resume => sub {
          die 'some error in resume';
        },
      ],
    );

    alien_checkpoint_ok;

    is(
      intercept { alien_resume_ok },
      array {
        event Ok => sub {
          call pass => F();
          call name => 'alien resume ok';
        };
        event Diag => sub {};
        event Diag => sub {
          call message => match(qr/error in resume: some error in resume/);
        };
        end;
      },
    );

  };

  subtest 'goodness and light' => sub {

    alienfile_ok q{ use alienfile };
    alien_checkpoint_ok;

    my $build;

    is(
      intercept { $build = alien_resume_ok },
      array {
        event Ok => sub {
          call pass => T();
          call name => 'alien resume ok';
        };
        end;
      },
    );

    isa_ok $build, 'Alien::Build';

  };

};

subtest 'targ' => sub {

  alienfile_ok source => q{
    use alienfile;
    die "targ = @{[ targ ]}" unless targ == 42;
  }, targ => 42;

};

alien_subtest 'alienfile_ok takes a already formed Alien::Build instance' => sub {

  my $build = alienfile q{ use alienfile };

  is(
    intercept { alienfile_ok $build },
    array {
      event Ok => sub {
        call pass => T();
        call name => 'alienfile compiled';
      };
      end;
    },
  );

  is(
    intercept { alienfile_ok undef },
    array {
      event Ok => sub {
        call pass => F();
        call name => 'alienfile compiled';
      };
      event Diag => sub {};
      event Diag => sub { call message => 'error: no alienfile given' };
      end;
    },
  );

};

subtest 'alienfile_skip_if_missing_prereqs' => sub {

  foreach my $phase (qw(share system ))
  {
    alien_subtest "no missing ($phase)" => sub {
      my($out, $build) = capture_merged { alienfile qq{ use alienfile; probe sub { '$phase' } } };
      note $out if $out;

      is
        intercept { alienfile_skip_if_missing_prereqs },
        [],
      ;
    };
  }

  alien_subtest 'missing configure' => sub {

    alienfile q{ use alienfile; configure { requires 'Bogus' => '1.23' } };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing configure prereq: Bogus 1.23';
        };
        end;
      };
    ;

  };

  alien_subtest 'missing configure (no version)' => sub {

    alienfile q{ use alienfile; configure { requires 'Bogus' } };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing configure prereq: Bogus undef';
        };
        end;
      };
    ;

  };


  alien_subtest 'missing share' => sub {

    alienfile q{
      use alienfile;
      probe sub { 'share' };
      share {
        requires 'Bogus2', '2.34';
      };
    };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing share prereq: Bogus2 2.34';
        };
      },
    ;

  };


  alien_subtest 'missing share (no version)' => sub {

    alienfile q{
      use alienfile;
      probe sub { 'share' };
      share {
        requires 'Bogus2';
      };
    };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing share prereq: Bogus2 undef';
        };
      },
    ;

  };

  alien_subtest 'missing system' => sub {

    alienfile q{
      use alienfile;
      probe sub { 'system' };
      sys {
        requires 'Bogus2', '2.34';
      };
    };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing system prereq: Bogus2 2.34';
        };
      },
    ;

  };


  alien_subtest 'missing system (no version)' => sub {

    alienfile q{
      use alienfile;
      probe sub { 'system' };
      sys {
        requires 'Bogus2';
      };
    };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing system prereq: Bogus2 undef';
        };
      },
    ;

  };

  alien_subtest 'mismatch' => sub {

    alienfile q{
      use alienfile;
      probe sub { 'system' };
      share {
        requires 'Bogus3', '9.99';
      };
    };

    is
      intercept { alienfile_skip_if_missing_prereqs },
      [],
    ;

    is
      intercept { alienfile_skip_if_missing_prereqs 'share' },
      array {
        event Plan => sub {
          call directive => 'SKIP';
          call reason    => 'Missing share prereq: Bogus3 9.99';
        };
      },
    ;

  };

};

done_testing;
