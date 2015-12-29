use strict;
use warnings;
use Test::Alien::CanCompile;
use Test::Stream ('-V1', SkipWithout => [ { 'Acme::Alien::DontPanic' => '0.025', 'Alien::Base' => '0.023' } ]);
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
