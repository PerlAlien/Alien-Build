package Alien::Build::Plugin::Probe::Vcpkg;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Probe for system libraries using Vcpkg
# VERSION

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 PROPERTIES

=head2 name

Specifies the name of the Vcpkg.  This should not be used with the C<lib> property below, choose only one.

=head2 lib

Specifies the list of libraries that make up the Vcpkg.  This should not be used with the C<name> property
above, choose only one.  Note that using this detection method, the version number of the package will
not be automatically determined (since multiple packages could potentially make up the list of libraries),
so you need to determine the version number another way if you need it.

This must be an array reference.

=cut

has 'name';
has 'lib';

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires('configure' => 'Alien::Build::Plugin::Probe::Vcpkg' => 0 );

  if($meta->prop->{platform}->{compiler_type} eq 'microsoft')
  {
    $meta->register_hook(
      probe => sub {
        my($build) = @_;
        eval {
          require Win32::Vcpkg;
          require Win32::Vcpkg::List;
          require Win32::Vcpkg::Package;
          Win32::Vcpkg->VERSION('0.02');
        };
        if(my $error = $@)
        {
          $build->log("unable to load Win32::Vcpkg: $error");
          return 'share';
        }

        my $package;
        if($self->name)
        {
          $package = Win32::Vcpkg::List->new
                                       ->search($self->name);
        }
        elsif($self->lib)
        {
          $DB::single = 1;
          $package = eval { Win32::Vcpkg::Package->new( lib => $self->lib ) };
          return 'share' if $@;
        }
        else
        {
          $build->log("you must provode either name or lib property for Probe::Vcpkg");
          return 'share';
        }

        my $version = $package->version;
        $version = 'unknown' unless defined $version;

        $build->install_prop->{plugin_probe_vcpkg} = {
          version => $version,
          cflags  => $package->cflags,
          libs    => $package->libs,
        };
        return 'system';
      },
    );

    $meta->register_hook(
      gather_system => sub {
        my($build) = @_;
        if(my $c = $build->install_prop->{plugin_probe_vcpkg})
        {
          $build->runtime_prop->{version} = $c->{version} unless defined $build->runtime_prop->{version};
          $build->runtime_prop->{$_} = $c->{$_} for qw( cflags libs );
        }
      },
    );
  }
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut

