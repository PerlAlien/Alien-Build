package Alien::Build::Plugin::PkgConfig::CommandLine;

use strict;
use warnings;
use 5.008004;
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

Note: in most case you will want to use L<Alien::Build::Plugin::PkgConfig::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin provides Probe and Gather steps for pkg-config based packages.  It uses
the best command line tools to accomplish this task.

=head1 PROPERTIES

=head2 pkg_name

The package name.  If this is a list reference then .pc files with all those package
names must be present.  The first name will be the primary and used by default once
installed.  For the subsequent C<.pc> files you can use the
L<Alien::Base alt method|Alien::Base/alt> to retrieve the alternate configurations
once the L<Alien> is installed.

=cut

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

# NOT used, for compat with other PkgConfig plugins
has register_prereqs => 1;

sub _bin_name {

  # We prefer pkgconf to pkg-config because it seems to be the future.

  require File::Which;
  File::Which::which($ENV{PKG_CONFIG})
    ? $ENV{PKG_CONFIG}
    : File::Which::which('pkgconf')
      ? 'pkgconf'
      : File::Which::which('pkg-config')
        ? 'pkg-config'
        : undef;
};

has bin_name => \&_bin_name;

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

sub _val
{
  my($build, $args, $prop_name) = @_;
  my $string = $args->{out};
  chomp $string;
  $string =~ s{^\s+}{};
  if($prop_name =~ /version$/)
  { $string =~ s{\s*$}{} }
  else
  { $string =~ s{\s*$}{ } }
  if($prop_name =~ /^(.*?)\.(.*?)\.(.*?)$/)
  { $build->runtime_prop->{$1}->{$2}->{$3} = $string }
  else
  { $build->runtime_prop->{$prop_name} = $string }
  ();
}

=head1 METHODS

=head2 available

 my $bool = Alien::Build::Plugin::PkgConfig::CommandLine->available;

Returns true if the necessary prereqs for this plugin are I<already> installed.

=cut

sub available
{
  !!_bin_name();
}

sub init
{
  my($self, $meta) = @_;

  my @probe;
  my @gather;

  my $pkgconf = $self->bin_name;

  unless(defined $meta->prop->{env}->{PKG_CONFIG})
  {
    $meta->prop->{env}->{PKG_CONFIG} = $pkgconf;
  }

  my($pkg_name, @alt_names) = (ref $self->pkg_name) ? (@{ $self->pkg_name }) : ($self->pkg_name);

  push @probe, map { [$pkgconf, '--exists', $_] } ($pkg_name, @alt_names);

  if(defined $self->minimum_version)
  {
    push @probe, [ $pkgconf, '--atleast-version=' . $self->minimum_version, $pkg_name ];
  }
  elsif(defined $self->atleast_version)
  {
    push @probe, [ $pkgconf, '--atleast-version=' . $self->atleast_version, $pkg_name ];
  }

  if(defined $self->exact_version)
  {
    push @probe, [ $pkgconf, '--exact-version=' . $self->exact_version, $pkg_name ];
  }

  if(defined $self->max_version)
  {
    push @probe, [ $pkgconf, '--max-version=' . $self->max_version, $pkg_name ];
  }

  push @probe, [ $pkgconf, '--modversion', $pkg_name, sub {
    my($build, $args) = @_;
    my $version = $args->{out};
    $version =~ s{^\s+}{};
    $version =~ s{\s*$}{};
    $build->hook_prop->{version} = $version;
  }];

  unshift @probe, sub {
    my($build) = @_;
    $build->runtime_prop->{legacy}->{name} ||= $pkg_name;
    $build->hook_prop->{probe_class} = __PACKAGE__;
    $build->hook_prop->{probe_instance_id} = $self->instance_id;
  };

  $meta->register_hook(
    probe => \@probe
  );

  push @gather, sub {
    my($build) = @_;
    die 'pkg-config command line probe does not match gather' if $build->hook_prop->{name} eq 'gather_system'
    &&                                                        ($build->install_prop->{system_probe_instance_id} || '') ne $self->instance_id;
  };
  push @gather, map { [ $pkgconf, '--exists', $_] } ($pkg_name, @alt_names);

  foreach my $prop_name (qw( cflags libs version ))
  {
    my $flag = $prop_name eq 'version' ? '--modversion' : "--$prop_name";
    push @gather,
      [ $pkgconf, $flag, $pkg_name, sub { _val @_, $prop_name } ];
    if(@alt_names)
    {
      foreach my $alt ($pkg_name, @alt_names)
      {
        push @gather,
          [ $pkgconf, $flag, $alt, sub { _val @_, "alt.$alt.$prop_name" } ];
      }
    }
  }

  foreach my $prop_name (qw( cflags libs ))
  {
    push @gather,
      [ $pkgconf, '--static', "--$prop_name", $pkg_name, sub { _val @_, "${prop_name}_static" } ];
    if(@alt_names)
    {
      foreach my $alt ($pkg_name, @alt_names)
      {
        push @gather,
          [ $pkgconf, '--static', "--$prop_name", $alt, sub { _val @_, "alt.$alt.${prop_name}_static" } ];
      }
    }
  }

  $meta->register_hook(gather_system => [@gather]);

  if($meta->prop->{platform}->{system_type} eq 'windows-mingw')
  {
    @gather = map {
      if(ref $_ eq 'ARRAY') {
        my($pkgconf, @rest) = @$_;
        [$pkgconf, '--dont-define-prefix', @rest],
      } else {
        $_
      }
    } @gather;
  }

  $meta->register_hook(gather_share => [@gather]);

  $meta->after_hook(
    $_ => sub {
      my($build) = @_;
      if(keys %{ $build->runtime_prop->{alt} } < 2)
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
