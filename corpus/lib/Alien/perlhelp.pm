package Alien::perlhelp;

use strict;
use warnings;
use parent qw( Alien::Base );

our $VERSION = '0.25';

sub exe { $^X }

sub alien_helper
{
  return {
    perlhelp => sub { __PACKAGE__->exe },
  };
}

1;
