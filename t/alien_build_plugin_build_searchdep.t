use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::SearchDep;
use lib 'corpus/lib';
use Alien::libfoo1;
use Alien::libfoo2;
use Capture::Tiny qw( capture_merged );
use Path::Tiny qw( path );

eval { require Archive::Tar; };
skip_all 'test requires Archive::Tar' if $@;
eval { require Env::ShellWords };
skip_all 'test requires Env::ShellWords' if $@;

my $corpus = path('corpus')->absolute;
$corpus =~ s{(\s)}{\\$1}g;

subtest basic => sub {

  delete $ENV{$_} for qw( CFLAGS CXXFLAGS LDFLAGS );

  my $build = alienfile q{

    use alienfile;

    share {

      plugin 'Download::Foo';

      plugin 'Build::SearchDep' => (
        aliens => 'Alien::libfoo2',
      );

      build sub {
        my($build) = @_;
        for(qw( CFLAGS CXXFLAGS LDFLAGS ))
        {
          die "$_ not defined !!" unless defined $ENV{$_};
          #print "$_=$ENV{$_}\n";
          $build->runtime_prop->{"my_$_"} = $ENV{$_};
        }
      };

      gather sub {
        my($build) = @_;

        $build->runtime_prop->{cflags} = '-core-cflag';
        $build->runtime_prop->{cflags_static} = '-core-cflag-static';
        $build->runtime_prop->{libs} = '-core-flag';
        $build->runtime_prop->{libs_static} = '-core-flag-static';
      };

    };

  };

  ok $build->requires('configure')->{'Alien::Build::Plugin::Build::SearchDep'}, 'set configure require for self';
  ok $build->requires('share')->{'Env::ShellWords'}, 'set share require for Env::ShellWords';
  is $build->requires('share')->{'Alien::libfoo2'}, 0, 'set share require for Alien::libfoo2';

  note scalar capture_merged {
    $build->load_requires($build->install_type);
    $build->download;
    $build->build;
  };

  is($build->runtime_prop->{cflags}, '-core-cflag', 'cflags');
  is($build->runtime_prop->{cflags_static}, '-core-cflag-static', 'cflags_static');

  is($build->runtime_prop->{libs}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib -core-flag", 'libs');
  is($build->runtime_prop->{libs_static}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib -core-flag-static", 'libs_static');

  is($build->runtime_prop->{my_CFLAGS}, "-I$corpus/lib/auto/share/dist/Alien-libfoo2/include", 'my_CFLAGS');
  is($build->runtime_prop->{my_CXXFLAGS}, "-I$corpus/lib/auto/share/dist/Alien-libfoo2/include", 'my_CXXFLAGS');
  is($build->runtime_prop->{my_LDFLAGS}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib", 'my_LDFLAGS');

};


subtest public_I => sub {

  delete $ENV{$_} for qw( CFLAGS CXXFLAGS LDFLAGS );

  my $build = alienfile q{

    use alienfile;

    share {

      plugin 'Download::Foo';

      plugin 'Build::SearchDep' => (
        aliens => 'Alien::libfoo2',
        public_I => 1,
      );

      build sub {};

      gather sub {
        my($build) = @_;

        $build->runtime_prop->{cflags} = '-core-cflag';
        $build->runtime_prop->{cflags_static} = '-core-cflag-static';
        $build->runtime_prop->{libs} = '-core-flag';
        $build->runtime_prop->{libs_static} = '-core-flag-static';
      };

    };

  };

  note scalar capture_merged {
    $build->load_requires($build->install_type);
    $build->download;
    $build->build;
  };

  is($build->runtime_prop->{cflags}, "-I$corpus/lib/auto/share/dist/Alien-libfoo2/include -core-cflag");
  is($build->runtime_prop->{cflags_static}, "-I$corpus/lib/auto/share/dist/Alien-libfoo2/include -core-cflag-static");
  is($build->runtime_prop->{libs}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib -core-flag");
  is($build->runtime_prop->{libs_static}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib -core-flag-static");
};


subtest public_l => sub {

  delete $ENV{$_} for qw( CFLAGS CXXFLAGS LDFLAGS );

  my $build = alienfile q{

    use alienfile;

    share {

      plugin 'Download::Foo';

      plugin 'Build::SearchDep' => (
        aliens => 'Alien::libfoo2',
        public_l => 1,
      );

      build sub {
      };

      gather sub {
        my($build) = @_;

        $build->runtime_prop->{cflags} = '-core-cflag';
        $build->runtime_prop->{cflags_static} = '-core-cflag-static';
        $build->runtime_prop->{libs} = '-core-flag';
        $build->runtime_prop->{libs_static} = '-core-flag-static';
      };

    };

  };

  note scalar capture_merged {
    $build->load_requires($build->install_type);
    $build->download;
    $build->build;
  };

  is($build->runtime_prop->{cflags}, '-core-cflag');
  is($build->runtime_prop->{cflags_static}, '-core-cflag-static');

  is($build->runtime_prop->{libs}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib -lfoo -lbar -lbaz -core-flag");
  is($build->runtime_prop->{libs_static}, "-L$corpus/lib/auto/share/dist/Alien-libfoo2/lib -lfoo -lbar -lbaz -core-flag-static");
};


subtest list => sub {

  my $build = alienfile q{

    use alienfile;

    plugin 'Build::SearchDep' => (
      aliens => [ 'Alien::libfoo1', 'Alien::libfoo2' ],
    );

    share {
    };

  };

  ok $build->requires('configure')->{'Alien::Build::Plugin::Build::SearchDep'}, 'set configure require for self';
  ok $build->requires('share')->{'Env::ShellWords'}, 'set share require for Env::ShellWords';
  is $build->requires('share')->{'Alien::libfoo1'}, 0, 'set share require for Alien::libfoo1';
  is $build->requires('share')->{'Alien::libfoo2'}, 0, 'set share require for Alien::libfoo2';

};

subtest hash => sub {

  my $build = alienfile q{

    use alienfile;

    plugin 'Build::SearchDep' => (
      aliens => { 'Alien::libfoo2' => '0.01'},
    );

    share {
    };

  };

  ok $build->requires('configure')->{'Alien::Build::Plugin::Build::SearchDep'}, 'set configure require for self';
  ok $build->requires('share')->{'Env::ShellWords'}, 'set share require for Env::ShellWords';
  is $build->requires('share')->{'Alien::libfoo2'}, '0.01', 'set share require for Alien::libfoo2';

};

done_testing;
