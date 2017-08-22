use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Core::Setup;
use Alien::Build::Plugin::Build::CMake;
use Alien::Build::Util qw( _dump );
use File::Which qw( which );

my %hash;

Alien::Build::Plugin::Core::Setup->_platform(\%hash);

$hash{cmake_generator} = Alien::Build::Plugin::Build::CMake::cmake_generator();
$hash{'pkg-config'}->{$_} = which($_) for qw( pkg-config pkgconf );
$hash{'pkg-config'}->{PKG_CONFIG} = which($ENV{PKG_CONFIG}) if defined $ENV{PKG_CONFIG};

ok 1;

diag '';
diag '';
diag '';

diag _dump(\%hash);

diag '';
diag '';

done_testing;
