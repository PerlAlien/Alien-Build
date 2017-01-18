package Alien::foomake;

use strict;
use warnings;

our $VERSION = '0.25';

sub exe { 'foomake.exe' }

sub alien_helper
{
  return {
    foomake1 => sub { Alien::foomake->exe },
    foomake2 => 'Alien::foomake->exe',
  };
}

1;
