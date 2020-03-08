package Alien::Build::Plugin::Probe::Vcpkg;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Probe for system libraries using Vcpkg
# VERSION

=head1 SYNOPSIS

 use alienfile;
 
 plugin 'Probe::Vcpkg' => (name => 'libffi');

=head1 DESCRIPTION

This plugin probe can be used to find "system" packages using Microsoft's C<Vcpkg> package manager for
Visual C++ builds of Perl.  C<Vcpkg> is a package manager for Visual C++ that includes a number of
open source packages.  Although C<Vcpkg> does also support Linux and macOS, this plugin does not
support finding C<Vcpkg> packages on those platforms.  For more details on C<Vcpkg>, see the project
github page here:

L<https://github.com/microsoft/vcpkg>

Here is the quick start guide for getting L<Alien::Build> to work with C<Vpkg>:

 # install Vcpkg
 C:\> git clone https://github.com/Microsoft/vcpkg.git
 C:\> cd vcpkg
 C:\vcpkg> .\bootstrap-vcpkg.bat
 C:\vcpkg> .\vcpkg integrate install
 
 # update PATH to include the bin directory
 # so that .DLL files can be found by Perl
 C:\vcpkg> path c:\vcpkg\installed\x64-windows\bin;%PATH%
 
 # install the packages that you want
 C:\vcpkg> .\vcpkg install libffi
 
 # install the alien that uses it
 C:\vcpkg> cpanm Alien::FFI

If you are using 32 bit build of Perl, then substitute C<x86-windows> for C<x64-windows>.  If you do
not want to add the C<bin> directory to the C<PATH>, then you can use C<x64-windows-static> instead,
which will provide static libraries.  (As of this writing static libraries for 32 bit Windows are not
available).  The main downside to using C<x64-windows-static> is that Aliens that require dynamic
libraries for FFI will not be installable.

If you do not want to install C<Vcpkg> user wide (the C<integrate install> command above), then you
can use the C<PERL_WIN32_VCPKG_ROOT> environment variable instead:

 # install Vcpkg
 C:\> git clone https://github.com/Microsoft/vcpkg.git
 C:\> cd vcpkg
 C:\vcpkg> .\bootstrap-vcpkg.bat
 C:\vcpkg> set PERL_WIN32_VCPKG_ROOT=c:\vcpkg

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

