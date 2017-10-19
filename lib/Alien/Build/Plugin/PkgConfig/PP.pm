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

The package name.  If this is a list reference then .pc files with all those package
names must be present.

=cut

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

=head2 minimum_version

The minimum required version that is acceptable version as provided by the system.

=cut

has minimum_version => undef;

=head1 METHODS

=head2 available

 my $bool = Alien::Build::Plugin::PkgConfig::PP->available;

Returns true if the necessary prereqs for this plugin are I<already> installed.

=cut

use constant _min_version => '0.14026';

# private for now, used by negotiator
has register_prereqs => 1;

sub available
{
  !!eval { require PkgConfig; PkgConfig->VERSION(_min_version) };
}

sub _cleanup
{
  my($value) = @_;
  $value =~ s{\s*$}{ };
  $value;
}

sub init
{
  my($self, $meta) = @_;

  if($self->register_prereqs)
  {
    $meta->add_requires('configure' => 'PkgConfig' => _min_version);
  }

  my($pkg_name, @alt_names) = (ref $self->pkg_name) ? (@{ $self->pkg_name }) : ($self->pkg_name);

  $meta->register_hook(
    probe => sub {
      my($build) = @_;
      $build->runtime_prop->{legacy}->{name} ||= $pkg_name;

      require PkgConfig;
      my $pkg = PkgConfig->find($pkg_name);
      die "package @{[ $pkg_name ]} not found" if $pkg->errmsg;
      if(defined $self->minimum_version)
      {
        my $version = PkgConfig::Version->new($pkg->pkg_version);
        my $need    = PkgConfig::Version->new($self->minimum_version);
        if($version < $need)
        {
          die "package @{[ $pkg_name ]} is not recent enough";
        }
      }

      foreach my $alt (@alt_names)
      {
        my $pkg = PkgConfig->find($alt);
        die "package $alt not found" if $pkg->errmsg;
      }

      'system';
    },
  );

  my $gather = sub {
    my($build) = @_;
    require PkgConfig;

    foreach my $name ($pkg_name, @alt_names)
    {
      require PkgConfig;
      my $pkg = PkgConfig->find($name, search_path => [@PKG_CONFIG_PATH]);
      if($pkg->errmsg)
      {
        $build->log("Trying to load the pkg-config information from the source code build");
        $build->log("of your package failed");
        $build->log("You are currently using the pure-perl implementation of pkg-config");
        $build->log("(AB Plugin is named PkgConfig::PP, which uses PkgConfig.pm");
        $build->log("It may work better with the real pkg-config.");
        $build->log("Try installing your OS' version of pkg-config or unset ALIEN_BUILD_PKG_CONFIG");
        die "second load of PkgConfig.pm @{[ $name ]} failed: @{[ $pkg->errmsg ]}"
      }
      my %prop;
      $prop{cflags}  = _cleanup scalar $pkg->get_cflags;
      $prop{libs}    = _cleanup scalar $pkg->get_ldflags;
      $prop{version} = $pkg->pkg_version;
      $pkg = PkgConfig->find($name, static => 1, search_path => [@PKG_CONFIG_PATH]);
      $prop{cflags_static} = _cleanup scalar $pkg->get_cflags;
      $prop{libs_static}   = _cleanup scalar $pkg->get_ldflags;
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
