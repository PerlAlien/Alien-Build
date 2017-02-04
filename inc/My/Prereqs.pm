package My::Prereqs;

use strict;
use warnings;
use base qw( Exporter );

our @EXPORT = qw( have_pkgconfig_bin );

sub have_pkgconfig_bin
{
  require IPC::Cmd;
  
  ($ENV{PKG_CONFIG} && IPC::Cmd::can_run($ENV{PKG_CONFIG})) || IPC::Cmd::can_run('pkgconf') || IPC::Cmd::can_run('pkg-config')
}

1;
