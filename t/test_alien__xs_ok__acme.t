use Test::Alien::CanCompile;
use Test2::Require::Module 'Acme::Alien::DontPanic' => '0.026';
use Test2::V0 -no_srand => 1;
use Test::Alien;

alien_ok 'Acme::Alien::DontPanic';
xs_ok do { local $/; <DATA> }, with_subtest {
  is Acme::answer(), 42, 'answer is 42';
};

done_testing;

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libdontpanic.h>

MODULE = Acme PACKAGE = Acme

int answer();
