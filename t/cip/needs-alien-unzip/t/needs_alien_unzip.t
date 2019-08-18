use Test2::V0 -no_srand => 1;
use Alien::Build;
use File::Which qw( which );
use Capture::Tiny qw( capture_merged );
use File::chdir;
use File::Glob qw( bsd_glob );
use Path::Tiny qw( path );
use Data::Dumper qw( Dumper );

sub run ($;$);
sub build_step ($$);

note "CWD=$CWD perl $] @{[ bsd_glob '~' ]}";

is
  [which 'unzip'],
  [],
  'unzip is not in path'
;

my $build = eval { Alien::Build->load('./alienfile') };

is $@, '', 'load';

eval { $build->load_requires('configure') };
is $@, '', 'load_requires(configure)';

$build->set_prefix('/opt/needs-alien-unzip');
$build->set_stage(path('./mystage')->absolute->stringify);

note Dumper($build);

is
  [$build->install_type],
  ['share'],
  'share install',
;

is
  $build->requires('share'),
  hash {
    field 'Alien::unzip' => D();
    field 'Archive::Zip' => DNE();
    etc;
  },
  'listed as required: Alien::unzip'
;

eval { require Archive::Zip };
eval { require Alien::unzip };

is
  \%INC,
  hash {
    field 'Archive/Zip.pm' => DNE();
    field 'Alien/unzip.pm' => DNE();
    etc;
  },
  'Archive::Zip and Alien::unzip aren\'t already installed',
;

my $cpanm_ok = run ['cpanm', '-n', sort keys %{ $build->requires('share') }], 'install share requires';

unless($cpanm_ok)
{
  my $log = path("~/.cpanm/latest-build/build.log");
  if(-f $log)
  {
    diag "## cpanm log $log ##";
    diag $log->slurp;
  }
  else
  {
    diag "NO LOG! $log DNE";
  }
}


eval { $build->load_requires('share') };
is $@, '', 'load_requires(share)';

is
  \%INC,
  hash {
    field 'Archive/Zip.pm' => DNE();
    field 'Alien/unzip.pm' => D();
    etc;
  },
  'Alien::unzip is installed',
;

build_step sub { $build->download }, 'download';

my $dir = build_step sub { $build->extract }, 'extract';

is
  [path($dir)->child('configure')->slurp],
  [path('src/configure')->slurp],
  'extracted zip'
;

sub run ($;$)
{
  my($cmd, $test_name) = @_;

  my $ctx = Test2::API::context();

  my @cmd = @$cmd;
  $test_name ||= "run command: @cmd";

  my($out, $exit) = capture_merged {
    print "+@cmd\n";
    system @cmd;
    $?;
  };

  is($exit, 0, $test_name);
  note $out;

  $ctx->release;

  $exit == 0;
}

sub build_step ($$)
{
  my($sub, $test_name) = @_;

  my $ctx = Test2::API::context();

  $test_name || die 'no test name given';

  my($out, $exception, $ret) = capture_merged {
    my $ret = eval { $sub->() };
    ($@, $ret);
  };

  is($exception, '', $test_name);
  note $out;

  $ctx->release;

  $ret;
}

done_testing;
