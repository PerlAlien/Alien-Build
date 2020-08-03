use 5.008004;
use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::Copy;
use Path::Tiny;

alien_subtest 'basic' => sub {

  my $build = alienfile_ok q{
    use alienfile;

    probe sub { 'share' };

    share {
      download sub { 
        Path::Tiny->new('foo')->touch;
      };
      extract sub {
        my $bin = Path::Tiny->new('.')->absolute->child('bin')->child('mycommand');
        log "bin=$bin";
        $bin->parent->mkpath;
        $bin->touch;
        $bin->chmod(0755) if $^O ne 'MSWin32';

        my $include = Path::Tiny->new('.')->absolute->child('include')->child('foo.h');
        $include->parent->mkpath;
        $include->touch;
      };
      plugin 'Build::Copy';
    };
  };

  alien_build_ok 'builds okay';

  my $stage = Path::Tiny->new($build->install_prop->{stage});

  my $mycommand = $stage->child('bin', 'mycommand');
  ok(-f $mycommand, "file $mycommand exists");
  ok(-x $mycommand, "file $mycommand is executable")
    if $^O !~ /^(MSWin32|msys)$/;

  my $inc = $stage->child('include','foo.h');
  ok(-f $inc, "file $inc exists");

  is(
    $build->requires('configure')->{'Alien::Build::Plugin::Build::Copy'},
    D(),
    'requires self',
  );

};

done_testing;
