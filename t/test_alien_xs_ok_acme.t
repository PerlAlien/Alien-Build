use strict;
use warnings;
use Test::Alien::CanCompile;
use Test2::Require::Module 'Acme::Alien::DontPanic' => '0.026';
use Test2::Require::Module 'Alien::Base' => '0.023';
use Test2::Bundle::Extended;
use Test::Alien;

plan 3;

alien_ok 'Acme::Alien::DontPanic';
xs_ok do { local $/; <DATA> }, with_subtest {
  plan 1;
  is Acme::answer(), 42, 'answer is 42';
};

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libdontpanic.h>

MODULE = Acme PACKAGE = Acme

int answer();
