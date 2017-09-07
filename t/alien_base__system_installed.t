use Test2::V0 -no_srand => 1;
use File::chdir;
use List::Util qw/shuffle/;

BEGIN { $ENV{ALIEN_FORCE} = 0; delete $ENV{ALIEN_INSTALL_TYPE} }

skip_all 'test requires Alien::Base::ModuleBuild 0.040 and Alien::Base::PkgConfig 0.040'
  unless (eval {
    require Alien::Base::PkgConfig;
    # when AB::PkgConfig is merged into Alien-Build
    # VERSION will be undef when testing out of git.
    # when that merge happens, this skip should
    # really be removed, but we are patching it here
    # so that the test doesn't get skipped in case
    # removing this skip is forgotten
    $Alien::Base::PkgConfig::VERSION ||= '0.040';
    Alien::Base::PkgConfig->VERSION('0.040');
  }) && (eval {
    require Alien::Base::ModuleBuild;
    Alien::Base::ModuleBuild->VERSION('0.040');
  });

# Since this is not a complete distribution, it complains about missing files/folders
local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /Can't (?:stat)|(?:find)/ };

$ENV{ALIEN_BLIB} = 0;

local $CWD;
push @CWD, qw/ corpus system_installed/;

my $pkg_config = Alien::Base::PkgConfig->pkg_config_command;

my $skip;
system( "$pkg_config --version" );
if ( $? ) {
  skip_all "Cannot use pkg-config: $?";
}

my @installed = shuffle map { /^(\S+)/ ? $1 : () } `$pkg_config --list-all`;
skip_all "Could not find any library for testing" unless @installed;

my ($lib, $cflags, $libs);

my $i = 1;

while (1) {

  $lib = shift @installed;
  last unless defined $lib;

  chomp( $cflags = `$pkg_config --cflags $lib` );
  chomp( $libs = `$pkg_config --libs $lib` );

  $cflags =~ s/\s*$//;
  $libs   =~ s/\s*$//;

  if ($lib and $cflags and $libs) {
    last;
  } 

  last if $i++ == 3;

  $lib    = undef;
  $cflags = undef;
  $libs   = undef;
}

skip_all "Could not find a suitable library for testing" unless defined $lib;

note "lib    = $lib\n";
note "cflags = $cflags\n";
note "libs   = $libs\n";

my $builder = Alien::Base::ModuleBuild->new( 
  module_name => 'MyTest', 
  dist_version => 0.01,
  alien_name => $lib,
  share_dir => 't',
); 

$builder->depends_on('build');

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

$builder->depends_on('realclean');

done_testing;

