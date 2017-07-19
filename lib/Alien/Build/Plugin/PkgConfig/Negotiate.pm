package Alien::Build::Plugin::PkgConfig::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
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

sub _pick
{
  my($class) = @_;

  return $ENV{ALIEN_BUILD_PKG_CONFIG} if $ENV{ALIEN_BUILD_PKG_CONFIG};
  
  if(eval q{ use PkgConfig::LibPkgConf 0.04; 1 })
  {
    return 'PkgConfig::LibPkgConf';
  }
  
  require Alien::Build::Plugin::PkgConfig::CommandLine;
  if(Alien::Build::Plugin::PkgConfig::CommandLine->new(pkg_name => 'foo')->bin_name)
  {
    unless($^O eq 'solaris' && $Config{ptrsize} == 8)
    {
      return 'PkgConfig::CommandLine';
    }
  }
  
  return 'PkgConfig::PP';
}

sub init
{
  my($self, $meta) = @_;
    
  $self->subplugin($self->_pick,
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
