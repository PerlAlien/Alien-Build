package My::Prereqs;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( have_pkgconfig_bin );

sub have_pkgconfig_bin
{
  require File::Which;
  
  ($ENV{PKG_CONFIG} && File::Which::which($ENV{PKG_CONFIG})) || File::Which::which('pkgconf') || File::Which::which('pkg-config')
}

1;
