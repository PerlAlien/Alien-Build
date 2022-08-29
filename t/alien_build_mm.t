use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build ();
use Alien::Build::MM qw( cmd );
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Capture::Tiny qw( capture_merged );
use Alien::Build::Util qw( _dump );

sub alienfile
{
  my($str) = @_;
  my(undef, $filename, $line) = caller;
  $str = '# line '. $line . ' "' . $filename . qq("\n) . $str;
  path('alienfile')->spew($str);
}

sub get_build
{
  my($build) = _args();
  $build;
}

@INC = map { ref $_ ? $_ : path($_)->absolute->stringify } @INC;

{ package Config::Foo; $Config::Foo::VERSION = 99; $INC{'Config/Foo.pm'} = __FILE__ }
{ package Config::Bar; $Config::Bar::VERSION = 99; $INC{'Config/Bar.pm'} = __FILE__ }

subtest 'basic' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    probe sub {
      $ENV{ALIEN_INSTALL_TYPE};
    };

    configure {
      requires 'Config::Foo' => '1.234',
      requires 'Config::Bar' => 0,
    };

    share {
      requires 'Share::Foo' => '4.567',
    };

    sys {
      requires 'Sys::Foo' => '9.99',
    };
  };

  subtest 'system' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'system';

    my $abmm = Alien::Build::MM->new;

    isa_ok $abmm, 'Alien::Build::MM';
    isa_ok $abmm->build, 'Alien::Build';

    my %args = $abmm->mm_args(
      DISTNAME => 'Alien-Foo',
      CONFIGURE_REQUIRES => {
        'YAML' => '1.2',
        'Dancer2' => '3.4',
        'Config::Foo' => '0.09',
        'Config::Bar' => '0.01',
      },
      BUILD_REQUIRES => {
        'Foo::Bar::Baz' => '1.23',
      },
    );

    is(path($abmm->build->install_prop->{stage})->basename, 'Alien-Foo', 'stage dir');
    note "stage = @{[ $abmm->build->install_prop->{stage} ]}";

    is(
      \%args,
      hash {
        field CONFIGURE_REQUIRES => hash {
          field 'Alien::Build::MM' => T();
          field 'YAML' => '1.2';
          field 'Dancer2' => '3.4';
          field 'Config::Foo' => '1.234';
          field 'Config::Bar' => '0.01';
        };
        field BUILD_REQUIRES => hash {
          field 'Alien::Build::MM' => T();
          field 'Foo::Bar::Baz' => '1.23';
          field 'Sys::Foo'      => '9.99';
        };
        field PREREQ_PM => hash {
          field 'Alien::Build' => T();
        };
        etc;
      },
    );

    undef $abmm;

    ok( -d '_alien', "left alien directory" );
    ok( -f '_alien/state.json', "left alien.json file" );

  };

  subtest 'share' => sub {

    local $ENV{ALIEN_INSTALL_TYPE} = 'share';

    my $abmm = Alien::Build::MM->new;

    isa_ok $abmm, 'Alien::Build::MM';
    isa_ok $abmm->build, 'Alien::Build';

    my %args = $abmm->mm_args(
      DISTNAME => 'Alien-Foo',
      CONFIGURE_REQUIRES => {
        'YAML' => '1.2',
        'Dancer2' => '3.4',
        'Config::Foo' => '0.09',
        'Config::Bar' => '0.01',
      },
      BUILD_REQUIRES => {
        'Foo::Bar::Baz' => '1.23',
      },
    );

    is(
      \%args,
      hash {
        field CONFIGURE_REQUIRES => hash {
          field 'Alien::Build::MM' => T();
          field 'YAML' => '1.2';
          field 'Dancer2' => '3.4';
          field 'Config::Foo' => '1.234';
          field 'Config::Bar' => '0.01';
        };
        field BUILD_REQUIRES => hash {
          field 'Alien::Build::MM' => T();
          field 'Foo::Bar::Baz' => '1.23';
          field 'Share::Foo'    => '4.567';
        };
        field PREREQ_PM => hash {
          field 'Alien::Build' => T();
        };
        etc;
      },
    );

  };

};

subtest 'mm_postamble' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  my $build = alienfile q{
    use alienfile;
    probe sub { 'system' };
  };

  my $abmm = Alien::Build::MM->new;

  $abmm->mm_args(
    DISTNAME => 'Alien-Foo',
  );

  my $postamble = $abmm->mm_postamble;

  ok $postamble, 'returned a true value';
  note $postamble;

};

subtest 'set_prefix' => sub {

  foreach my $type (qw( perl site vendor ))
  {

    subtest "type = $type" => sub {

      local $CWD = tempdir( CLEANUP => 1 );

      alienfile q{
        use alienfile;
        probe sub { 'share' };
      };

      my @dirs = map { path($CWD)->child('foo')->child($_) } qw( perl site vendor );
      $_->mkpath for @dirs;

      do {
        my $abmm = Alien::Build::MM->new;
        $abmm->mm_args(
          DISTNAME => 'Alien-Foo',
        );
      };

      note capture_merged {
        local @ARGV = ($type, @dirs);
        prefix();
      };

      ok( -f '_alien/mm/prefix', 'touched prefix' );

      my $build = Alien::Build->resume('alienfile', '_alien');
      my $prefix = path($build->runtime_prop->{prefix})->relative($CWD)->stringify;
      is $prefix, "foo/$type/auto/share/dist/Alien-Foo", "correct path";
    };
  }

};

subtest 'download + build' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  $main::call_download = 0;
  $main::call_build    = 0;

  alienfile q{
    use alienfile;
    plugin 'Test::Mock',
      probe        => 'share',
      check_digest => 1;

    use Path::Tiny qw( path );

    share {
      download sub {
        my($build) = @_;
        my $path = path('foo.tar.gz')->absolute;
        $path->spew('foo');
        $build->install_prop->{download_detail}->{"$path"} = {
          protocol => 'file',
          digest   => [ FAKE => 'deadbeaf' ],
        };
        print " + IN DOWNLOAD +\n";
        $main::call_download = 1;
      };
      extract sub {
        print " + IN EXTRACT +\n";
        path('file1')->spew('foo1');
        path('file2')->spew('foo2');
      };
      build sub {
        print " + IN BUILD +\n";
        $main::call_build = 1;
      };
    };
  };

  my $abmm = Alien::Build::MM->new;

  $abmm->mm_args(
    DISTNAME => 'Alien-Foo',
  );

  note capture_merged {
    local @ARGV = ('perl', map { ($_,$_,$_) } tempdir( CLEANUP => 1 ));
    prefix();
  };

  my($out, $error) = capture_merged {
    local @ARGV = ();
    eval { download() };
    $@;
  };
  note $out if $out ne '';

  is($error, '', 'no error in download') || do {
    diag _dump(get_build()->install_prop);
    return;
  };
  note _dump(get_build()->install_prop);

  ok( -f '_alien/mm/download', 'touched download' );
  is $main::call_download, 1, 'download';

  ($out, $error) = capture_merged {
    local @ARGV = ();
    eval { build() };
    $@;
  };
  note $out if $out ne '';

  is($error, '', 'no error in build') || do {
    diag _dump(get_build()->install_prop);
    return;
  };
  note _dump(get_build()->install_prop);

  ok( -f '_alien/mm/build', 'touched build' );
  is $main::call_build, 1, 'build';

};

subtest 'patch' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
  };

  path('patch')->mkpath;
  path('patch/foo.txt')->touch;

  my $abmm = Alien::Build::MM->new;

  ok( $abmm->build->install_prop->{patch}, 'patch is defined' );

  ok( -f path($abmm->build->install_prop->{patch})->child('foo.txt'), 'got the correct directory' );
};

subtest 'clean_install' => sub {

  local $CWD = tempdir( CLEANUP => 1 );

  alienfile q{
    use alienfile;
    probe sub { 'share' };
  };

  my @dirs = map { path($CWD)->child('foo')->child($_) } qw( perl site vendor );
  $_->mkpath for @dirs;

  my $abmm = Alien::Build::MM->new( clean_install => 1 );
  is( $abmm->clean_install, T() );

  my %args = $abmm->mm_args( DISTNAME => 'AlienFoo' );
  is(
    \%args,
    hash {
      field CONFIGURE_REQUIRES => hash {
        field 'Alien::Build::MM' => '1.74';
        etc;
      };
      field BUILD_REQUIRES => hash {
        field 'Alien::Build::MM' => '1.74';
        etc;
      };
      field PREREQ_PM => hash {
        field 'Alien::Build' => '1.74';
        etc;
      };
      etc;
    },
  );


};

done_testing;
