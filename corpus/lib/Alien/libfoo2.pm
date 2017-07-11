package Alien::libfoo2;

use strict;
use warnings;
use base qw( Alien::Base );

sub alien_helper
{
  return {
    foo1 => sub { 'bar' . (1+2) },
    foo2 => '"baz" . (3+4)',
  };
}

1;
