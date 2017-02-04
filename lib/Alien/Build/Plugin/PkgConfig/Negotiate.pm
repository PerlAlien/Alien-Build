package Alien::Build::Plugin::PkgConfig::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;
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

sub _pick
{
  my($class) = @_;
  
  if(eval q{ use PkgConfig::LibPkgConf 0.04; 1 })
  {
    return 'LibPkgConf';
  }
  
  require Alien::Build::Plugin::PkgConfig::CommandLine;
  if(Alien::Build::Plugin::PkgConfig::CommandLine->new->bin_name)
  {
    return 'CommandLine';
  }
  
  return 'PP';
}

sub init
{
  my($self, $meta) = @_;
  
  my $plugin = _plugin($self->_pick, pkg_name => $self->pkg_name);
  $plugin->init($meta);
  $self;
}

sub _plugin
{
  my($name, @args) = @_;
  my $class = "Alien::Build::Plugin::PkgConfig::$name";
  my $pm    = "Alien/Build/Plugin/PkgConfig/$name.pm";
  require $pm;
  $class->new(@args);
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
