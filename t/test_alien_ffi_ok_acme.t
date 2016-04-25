use strict;
use warnings;
use Test2::Require::Module 'Acme::Alien::DontPanic' => '0.026';
use Test2::Require::Module 'Alien::Base' => '0.023';
use Test2::Bundle::Extended;
use Test::Alien::CanCompile;
use Test::Alien;

plan 3;

alien_ok 'Acme::Alien::DontPanic';
ffi_ok { symbols => ['answer'] } , with_subtest {
  my($ffi) = @_;
  plan 1;
  is $ffi->function('answer' => [] => 'int')->call(), 42, 'answer is 42';
};

__DATA__

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <libdontpanic.h>

MODULE = Acme PACKAGE = Acme

int answer();
