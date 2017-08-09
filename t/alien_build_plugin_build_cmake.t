use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Alien::Build::Plugin::Build::CMake;

alienfile_ok q{
  use alienfile;
  plugin 'Build::CMake';
};

done_testing
