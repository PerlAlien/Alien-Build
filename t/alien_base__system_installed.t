use lib 't/lib';
use MyTest::System;
use Test2::V0 -no_srand => 1;
use Test2::Mock;
use File::chdir;
use List::Util qw/shuffle/;
use Capture::Tiny qw( capture_merged );
use File::chdir;
use File::Temp qw( tempdir );
use Path::Tiny qw( path );
use Alien::Base::PkgConfig;

BEGIN { $ENV{ALIEN_FORCE} = 0; delete $ENV{ALIEN_INSTALL_TYPE} }

skip_all 'test requires Alien::Base::ModuleBuild'
  unless (eval {
    require Alien::Base::ModuleBuild;
    Alien::Base::ModuleBuild->VERSION('0.040');
  });

subtest 'basic' => sub {

  # Since this is not a complete distribution, it complains about missing files/folders
  local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /Can't (?:stat)|(?:find)/ };
  local $CWD = tempdir( CLEANUP => 1 );

  {
    path('MANIFEST')->spew(
      "lib/MyTest.pm\n",
      "MANIFEST\t\t\tThis list of files\n",
    );
    path('lib')->mkpath;
    path('lib/MyTest.pm')->spew(
      "package MyTest;\n",
      "\n",
      "use strict;\n",
      "use warnings;\n",
      "use base 'Alien::Base';\n",
      "\n",
      "1;\n",
    );
  }

  my $lib    = 'libfoo';
  my $cflags = '-I/opt/foo/bar/baz/include';
  my $libs   = '-L/opt/foo/bar/baz/lib -lfoo';

  my $gard = system_fake
    'pkg-config' => sub {
      my(@args) = @_;

      if($args[0] eq '--modversion' && $args[1])
      {
        print "1.2.3\n";
        return 0;
      }
      if($args[0] eq '--cflags' && $args[1])
      {
        print "$cflags \n";
        return 0;
      }
      if($args[0] eq '--libs' && $args[1])
      {
        print "$libs \n";
        return 0;
      }

      use Alien::Build::Util qw( _dump );
      diag _dump(\@args);
      ok 0, 'bad command';
      return 2;
    },
  ;

  my $mock = Test2::Mock->new(
    class => 'Alien::Base::PkgConfig',
    override => [
      pkg_config_command => sub {
        'pkg-config',
      },
    ],
  );

  my $pkg_config = Alien::Base::PkgConfig->pkg_config_command;

  note "lib    = $lib\n";
  note "cflags = $cflags\n";
  note "libs   = $libs\n";

  my($builder) = do {
    my($out, $builder) = capture_merged {
      Alien::Base::ModuleBuild->new(
        module_name => 'MyTest',
        dist_version => 0.01,
        alien_name => $lib,
        share_dir => 't',
      );
    };
    note $out;
    $builder;
  };

  note scalar capture_merged { $builder->depends_on('build') };

  {
    local $CWD;
    push @CWD, qw/blib lib/;

    use lib '.';
    require './MyTest.pm';
    my $alien = MyTest->new;

    isa_ok($alien, 'MyTest');
    isa_ok($alien, 'Alien::Base');

    note "alien->cflags = ", $alien->cflags;
    note "alien->libs   = ", $alien->libs;

    is($alien->cflags, $cflags, "get cflags from system-installed library");
    is($alien->libs  , $libs  , "get libs from system-installed library"  );
  }

  note scalar capture_merged { $builder->depends_on('realclean') };
};

done_testing;

