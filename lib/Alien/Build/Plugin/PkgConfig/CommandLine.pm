package Alien::Build::Plugin::PkgConfig::CommandLine;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Probe system and determine library or tool properties using the pkg-config command line interface
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'PkgConfig::CommandLine' => (
   pkg_name => 'libfoo',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin provides Probe and Gather steps for pkg-config based packages.  It uses
the best command line tools to accomplish this task.

=head1 PROPERTIES

=head2 pkg_name

The package name.

=cut

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

=head2 minimum_version

The minimum required version that is acceptable version as provided by the system.

=cut

has minimum_version => undef;

sub _val
{
  my($build, $args, $prop_name) = @_;
  my $string = $args->{out};
  chomp $string;
  $string =~ s{^\s+}{};
  if($prop_name eq 'version')
  { $string =~ s{\s*$}{} }
  else
  { $string =~ s{\s*$}{ } }
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
  
  if(defined $self->minimum_version)
  {
    push @probe, [ $pkgconf, '--atleast-version=' . $self->minimum_version, $self->pkg_name ];
  }
  
  $meta->register_hook(
    probe => \@probe
  );
  
  my @gather_system;
  
  foreach my $prop_name (qw( cflags libs version ))
  {
    my $flag = $prop_name eq 'version' ? '--modversion' : "--$prop_name";
    push @gather_system,
      [ $pkgconf, $flag, $self->pkg_name, sub { _val @_, $prop_name } ];
  }

  foreach my $prop_name (qw( cflags libs ))
  {
    my $flag = $prop_name eq 'version' ? '--modversion' : "--$prop_name";
    push @gather_system,
      [ $pkgconf, '--static', $flag, $self->pkg_name, sub { _val @_, "${prop_name}_static" } ];
  }
  
  $meta->register_hook(
    $_ => \@gather_system,
  ) for qw( gather_system gather_share );
  
  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::PkgConfig::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
