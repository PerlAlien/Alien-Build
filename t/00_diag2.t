use Test2::V0 -no_srand => 1;
use Alien::Build::Plugin::Core::Setup;
use Alien::Build::Util qw( _dump );

my %hash;

Alien::Build::Plugin::Core::Setup->_platform(\%hash);

ok 1;

diag '';
diag '';
diag '';

diag _dump(\%hash);

diag '';
diag '';

done_testing;
