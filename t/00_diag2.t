use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Core::Setup;
use Alien::Build::Plugin::Build::CMake;
use Alien::Build::Util qw( _dump );

my %hash;

Alien::Build::Plugin::Core::Setup->_platform(\%hash);

$hash{cmake_generator} = Alien::Build::Plugin::Build::CMake::cmake_generator();

ok 1;

diag '';
diag '';
diag '';

diag _dump(\%hash);

diag '';
diag '';

done_testing;
