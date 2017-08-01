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

The package name.  If this is a list reference then .pc files with all those package
names must be present.

=cut

has '+pkg_name' => sub {
  Carp::croak "pkg_name is a required property";
};

has bin_name => sub {

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

sub init
{
  my($self, $meta) = @_;
  
  my $pkgconf = $self->bin_name;

  my($pkg_name, @alt_names) = (ref $self->pkg_name) ? (@{ $self->pkg_name }) : ($self->pkg_name);
  
  my @probe = map { [$pkgconf, '--exists', $_] } ($pkg_name, @alt_names);
  
  if(defined $self->minimum_version)
  {
    push @probe, [ $pkgconf, '--atleast-version=' . $self->minimum_version, $pkg_name ];
  }

  unshift @probe, sub {
    my($build) = @_;
    $build->runtime_prop->{legacy}->{name} ||= $pkg_name;
  };
  
  $meta->register_hook(
    probe => \@probe
  );
  
  my @gather = map { [ $pkgconf, '--exists', $_] } ($pkg_name, @alt_names);
  
  foreach my $prop_name (qw( cflags libs version ))
  {
    my $flag = $prop_name eq 'version' ? '--modversion' : "--$prop_name";
    push @gather,
      [ $pkgconf, $flag, $pkg_name, sub { _val @_, $prop_name } ];
    foreach my $alt ($pkg_name, @alt_names)
    {
      push @gather,
        [ $pkgconf, $flag, $alt, sub { _val @_, "alt.$alt.$prop_name" } ];
    }
  }

  foreach my $prop_name (qw( cflags libs ))
  {
    push @gather,
      [ $pkgconf, '--static', "--$prop_name", $pkg_name, sub { _val @_, "${prop_name}_static" } ];
    foreach my $alt ($pkg_name, @alt_names)
    {
      push @gather,
        [ $pkgconf, '--static', "--$prop_name", $alt, sub { _val @_, "alt.$alt.${prop_name}_static" } ];
    }
  }
  
  $meta->register_hook(
    $_ => \@gather,
  ) for qw( gather_system gather_share );

  $meta->after_hook(
    $_ => sub {
      my($build) = @_;
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
