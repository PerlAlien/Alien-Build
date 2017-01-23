package Alien::Build::Plugin::PkgConfig::CommandLine;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Probe system and determine library or tool properties using the pkg-config command line interface
# VERSION

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

has bin_name => sub {

  # We prefer pkgconf to pkg-config because it seems to be the future.

  require IPC::Cmd;
  IPC::Cmd::can_run($ENV{PKG_CONFIG})
    ? $ENV{PKG_CONFIG}
    : IPC::Cmd::can_run('pkgconf')
      ? 'pkgconf'
      : IPC::Cmd::can_run('pkg-config')
        ? 'pkg-config'
        : undef;
};

has minimum_version => undef;

sub _val
{
  my($build, $args, $prop_name) = @_;
  my $string = $args->{out};
  chomp $string;
  $string =~ s{^\s+}{};
  $string =~ s{\s+$}{ };
  $build->runtime_prop->{$prop_name} = $string;
  ();
}

sub init
{
  my($self, $meta) = @_;
  
  my $pkgconf = $self->bin_name;
  
  my @probe = (
    [$pkgconf, '--exists', $self->pkg_name],
  );
  
  if($self->minimum_version)
  {
    push @probe, [ $pkgconf, '--atleast-version=' . $self->minimum_version, $self->pkg_name ];
  }
  
  $meta->register_hook(
    probe => \@probe
  );
  
  my @gather_system;
  
  foreach my $prop_name (qw( cflags libs version ))
  {
    push @gather_system,
      [ $pkgconf, "--$prop_name", $self->pkg_name, sub { _val @_, $prop_name } ];
  }
  
  $meta->register_hook(
    gather_system => \@gather_system,
  );
}

1;
