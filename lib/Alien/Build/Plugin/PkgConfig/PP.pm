package Alien::Build::Plugin::PkgConfig::PP;

use strict;
use warnings;
use Alien::Build::Plugin;
use Carp ();
use Env qw( @PKG_CONFIG_PATH );

# ABSTRACT: Probe system and determine library or tool properties using PkgConfig.pm
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'PkgConfig::PP' => (
   pkg_name => 'libfoo',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin provides Probe and Gather steps for pkg-config based packages.  It uses
L<PkgConfig> to accomplish this task.

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

sub _cleanup
{
  my($value) = @_;
  $value =~ s{\s*$}{ };
  $value;
}

sub init
{
  my($self, $meta) = @_;
  
  my $caller = caller;
  
  if($caller ne 'Alien::Build::Plugin::PkgConfig::Negotiate')
  {
    $meta->add_requires('configure' => 'PkgConfig' => '0.14026');
  }

  $meta->register_hook(
    probe => sub {
      my($build) = @_;
      $build->runtime_prop->{legacy}->{name} ||= $self->pkg_name;

      require PkgConfig;
      my $pkg = PkgConfig->find($self->pkg_name);
      die "package @{[ $self->pkg_name ]} not found" if $pkg->errmsg;
      if(defined $self->minimum_version)
      {
        my $version = PkgConfig::Version->new($pkg->pkg_version);
        my $need    = PkgConfig::Version->new($self->minimum_version);
        if($version < $need)
        {
          die "package @{[ $self->pkg_name ]} is not recent enough";
        }
      }
      'system';
    },
  );

  my $gather = sub {
    my($build) = @_;
    require PkgConfig;
    my $pkg = PkgConfig->find($self->pkg_name, search_path => [@PKG_CONFIG_PATH]);
    die "second load of PkgConfig.pm @{[ $self->pkg_name ]} failed: @{[ $pkg->errmsg ]}"
      if $pkg->errmsg;
    $build->runtime_prop->{cflags}  = _cleanup scalar $pkg->get_cflags;
    $build->runtime_prop->{libs}    = _cleanup scalar $pkg->get_ldflags;
    $build->runtime_prop->{version} = $pkg->pkg_version;
    $pkg = PkgConfig->find($self->pkg_name, static => 1, search_path => [@PKG_CONFIG_PATH]);
    $build->runtime_prop->{cflags_static} = _cleanup scalar $pkg->get_cflags;
    $build->runtime_prop->{libs_static}   = _cleanup scalar $pkg->get_ldflags;
  };
  
  $meta->register_hook(
    gather_system => $gather,
  );

  $meta->register_hook(
    gather_share => $gather,
  );
  
  $self;
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::PkgConfig::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
