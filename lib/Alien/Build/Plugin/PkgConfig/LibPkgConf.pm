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

Note: in most case you will want to use L<Alien::Build::Plugin::PkgConfig::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin provides Probe and Gather steps for pkg-config based packages.  It uses
L<PkgConfig::LibPkgConf> to accomplish this task.

This plugin is part of the Alien::Build core For Now, but may be removed in a future
date.  While It Seemed Like A Good Idea at the time, it may not be appropriate to keep
it in core.  If it is spun off it will get its own distribution some time in the future.

=head1 PROPERTIES

=head2 pkg_name

The package name.  If this is a list reference then .pc files with all those package
names must be present.

=cut

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

=head2 atleast_version

The minimum required version that is acceptable version as provided by the system.

=cut

has atleast_version => undef;

=head2 exact_version

The exact required version that is acceptable version as provided by the system.

=cut

has exact_version => undef;

=head2 max_version

The max required version that is acceptable version as provided by the system.

=cut

has max_version => undef;

=head2 minimum_version

Alias for C<atleast_version> for backward compatibility.

=cut

has minimum_version => undef;

# private for now, used by negotiator
has register_prereqs => 1;

=head1 METHODS

=head2 available

 my $bool = Alien::Build::Plugin::PkgConfig::LibPkgConf->available;

Returns true if the necessary prereqs for this plugin are I<already> installed.

=cut

use constant _min_version => '0.04';

sub available
{
  !!eval { require PkgConfig::LibPkgConf; PkgConfig::LibPkgConf->VERSION(_min_version) };
}

sub init
{
  my($self, $meta) = @_;

  unless(defined $meta->prop->{env}->{PKG_CONFIG})
  {
    # TODO: this doesn't yet find pkgconf in the bin dir of a share
    # install.
    my $command_line =
      File::Which::which('pkgconf')
      ? 'pkgconf'
      : File::Which::which('pkg-config')
        ? 'pkg-config'
        : undef;
    $meta->prop->{env}->{PKG_CONFIG} = $command_line
      if defined $command_line;
  }

  if($self->register_prereqs)
  {
    # Also update in Neotiate.pm
    $meta->add_requires('configure' => 'PkgConfig::LibPkgConf::Client' => _min_version);

    if(defined $self->minimum_version || defined $self->atleast_version || defined $self->exact_version || defined $self->max_version)
    {
      $meta->add_requires('configure' => 'PkgConfig::LibPkgConf::Util' => _min_version);
    }
  }

  my($pkg_name, @alt_names) = (ref $self->pkg_name) ? (@{ $self->pkg_name }) : ($self->pkg_name);

  $meta->register_hook(
    probe => sub {
      my($build) = @_;
      $build->runtime_prop->{legacy}->{name} ||= $pkg_name;

      require PkgConfig::LibPkgConf::Client;
      my $client = PkgConfig::LibPkgConf::Client->new;
      my $pkg = $client->find($pkg_name);
      die "package $pkg_name not found" unless $pkg;

      $build->hook_prop->{version} = $pkg->version;
      my $atleast_version = $self->atleast_version;
      $atleast_version = $self->minimum_version unless defined $self->atleast_version;
      if($atleast_version)
      {
        require PkgConfig::LibPkgConf::Util;
        if(PkgConfig::LibPkgConf::Util::compare_version($pkg->version, $atleast_version) < 0)
        {
          die "package $pkg_name is version @{[ $pkg->version ]}, but at least $atleast_version is required.";
        }
      }

      if($self->exact_version)
      {
        require PkgConfig::LibPkgConf::Util;
        if(PkgConfig::LibPkgConf::Util::compare_version($pkg->version, $self->exact_version) != 0)
        {
          die "package $pkg_name is version @{[ $pkg->version ]}, but exactly @{[ $self->exact_version ]} is required.";
        }
      }

      if($self->max_version)
      {
        require PkgConfig::LibPkgConf::Util;
        if(PkgConfig::LibPkgConf::Util::compare_version($pkg->version, $self->max_version) > 0)
        {
          die "package $pkg_name is version @{[ $pkg->version ]}, but max @{[ $self->max_version ]} is required.";
        }
      }

      foreach my $alt (@alt_names)
      {
        my $pkg = $client->find($alt);
        die "package $alt not found" unless $pkg;
      }

      'system';
    },
  );

  $meta->register_hook(
    $_ => sub {
      my($build) = @_;
      require PkgConfig::LibPkgConf::Client;
      my $client = PkgConfig::LibPkgConf::Client->new;

      foreach my $name ($pkg_name, @alt_names)
      {
        my $pkg = $client->find($name);
        die "reload of package $name failed" unless defined $pkg;

        my %prop;
        $prop{version}        = $pkg->version;
        $prop{cflags}         = $pkg->cflags;
        $prop{libs}           = $pkg->libs;
        $prop{cflags_static}  = $pkg->cflags_static;
        $prop{libs_static}    = $pkg->libs_static;
        $build->runtime_prop->{alt}->{$name} = \%prop;
      }

      foreach my $key (keys %{ $build->runtime_prop->{alt}->{$pkg_name} })
      {
        $build->runtime_prop->{$key} = $build->runtime_prop->{alt}->{$pkg_name}->{$key};
      }

      if(keys %{ $build->runtime_prop->{alt} } == 1)
      {
        delete $build->runtime_prop->{alt};
      }
    },
  ) for qw( gather_system gather_share );

  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::PkgConfig::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
