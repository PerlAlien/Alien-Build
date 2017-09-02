package Alien::Build::Plugin::PkgConfig::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
use Alien::Build::Plugin::PkgConfig::CommandLine;
use Alien::Build::Plugin::PkgConfig::LibPkgConf;
use Alien::Build::Plugin::PkgConfig::PP;
use Config;
use Carp ();

# ABSTRACT: Package configuration negotiation plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'PkgConfig' => (
   pkg_name => 'libfoo',
 );

=head1 DESCRIPTION

This plugin provides Probe and Gather steps for pkg-config based packages.  It picks
the best C<PkgConfig> plugin depending your platform and environment.

=head1 PROPERTIES

=head2 pkg_name

The package name.

=cut

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

=head2 minimum_version

The minimum required version that is acceptable version as provided by the system.

=cut

has minimum_version => undef;

=head1 METHODS

=head2 pick

 my $name = Alien::Build::Plugijn::PkgConfig::Negotiate->pick;

Returns the name of the negotiated plugin.

=cut

sub pick
{
  my($class) = @_;

  return $ENV{ALIEN_BUILD_PKG_CONFIG} if $ENV{ALIEN_BUILD_PKG_CONFIG};
  
  if(Alien::Build::Plugin::PkgConfig::LibPkgConf->available)
  {
    return 'PkgConfig::LibPkgConf';
  }
  
  if(Alien::Build::Plugin::PkgConfig::CommandLine->available)
  {
    unless($^O eq 'solaris' && $Config{ptrsize} == 8)
    {
      return 'PkgConfig::CommandLine';
    }
  }
  
  if(Alien::Build::Plugin::PkgConfig::PP->available)
  {
    return 'PkgConfig::PP';
  }
  else
  {
    Carp::carp("Could not find an appropriate pkg-config implementation, please install PkgConfig.pm, PkgConfig::LibPkgConf, pkg-config or pkgconf");
  }
}

sub init
{
  my($self, $meta) = @_;

  my $plugin = $self->pick;
  Alien::Build->log("Using PkgConfig plugin: $plugin");
  
  if(ref($self->pkg_name) eq 'ARRAY')
  {
    $meta->add_requires('configure', 'Alien::Build::Plugin::PkgConfig::Negotiate' => '0.79');
  }
  
  $self->subplugin($plugin,
    pkg_name        => $self->pkg_name,
    minimum_version => $self->minimum_version,
  )->init($meta);

  $self;
}

1;

=head1 ENVIRONMENT

=over 4

=item ALIEN_BUILD_PKG_CONFIG

If set, this plugin will be used instead of the build in logic
which attempts to automatically pick the best plugin.

=back

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
