package Alien::Build::Interpolate::Default;

use strict;
use warnings;
use base qw( Alien::Build::Interpolate );

# ABSTRACT: Default interpolator for Alien::Build
# VERSION

sub new
{
  my($class) = @_;
  my $self = $class->SUPER::new(@_);
  $self;
}

1;
