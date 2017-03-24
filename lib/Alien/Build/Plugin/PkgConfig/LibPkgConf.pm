package Alien::Build::Plugin::PkgConfig::LibPkgConf;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();

# ABSTRACT: Probe system and determine library or tool properties using PkgConfig::LibPkgConf
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'PkgConfig::LibPkgConf' => (
   pkg_name => 'libfoo',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin provides Probe and Gather steps for pkg-config based packages.  It uses
L<PkgConfig::LibPkgConf> to accomplish this task.

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

sub init
{
  my($self, $meta) = @_;

  my $caller = caller;
  
  if($caller ne 'Alien::Build::Plugin::PkgConfig::Negotiate')
  {
    # Also update in Neotiate.pm
    $meta->add_requires('configure' => 'PkgConfig::LibPkgConf::Client' => '0.04');
  
    if(defined $self->minimum_version)
    {
      $meta->add_requires('configure' => 'PkgConfig::LibPkgConf::Util' => '0.04');
    }
  }
  
  $meta->register_hook(
    probe => sub {
      my($build) = @_;
      $build->runtime_prop->{legacy}->{name} ||= $self->pkg_name;
    
      require PkgConfig::LibPkgConf::Client;
      my $client = PkgConfig::LibPkgConf::Client->new;
      my $pkg = $client->find($self->pkg_name);
      die "package @{[ $self->pkg_name ]} not found" unless $pkg;
      if(defined $self->minimum_version)
      {
        require PkgConfig::LibPkgConf::Util;
        if(PkgConfig::LibPkgConf::Util::compare_version($pkg->version, $self->minimum_version) == -1)
        {
          die "package @{[ $self->pkg_name ]} is not recent enough";
        }
      }
      'system';
    },
  );
  
  $meta->register_hook(
    $_ => sub {
      my($build) = @_;
      require PkgConfig::LibPkgConf::Client;
      my $client = PkgConfig::LibPkgConf::Client->new;
      my $pkg = $client->find($self->pkg_name);
      die "reload of package @{[ $self->pkg_name ]} failed" unless defined $pkg;
      
      $build->runtime_prop->{version}        = $pkg->version;
      $build->runtime_prop->{cflags}         = $pkg->cflags;
      $build->runtime_prop->{libs}           = $pkg->libs;
      $build->runtime_prop->{cflags_static}  = $pkg->cflags_static;
      $build->runtime_prop->{libs_static}    = $pkg->libs_static;
    },
  ) for qw( gather_system gather_share );
  
  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::PkgConfig::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
