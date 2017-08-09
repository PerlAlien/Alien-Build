package Alien::Build::Plugin::Build::CMake;

use strict;
use warnings;
use 5.008001;
use Alien::Build::Plugin;

# ABSTRACT: CMake plugin for Alien::Build
# VERSION

=head1 SYNOPSIS

 use alienfile;
 
 share {
   plugin 'Build::CMake';
 };

=head1 DESCRIPTION

This plugin helps build alienized projects that use C<cmake>.
The intention is to make this a core L<Alien::Build> plugin if/when
it becomes stable enough.

=head1 SEE ALSO

=over 4

=item L<Alien::Build>

=item L<Alien::Build::Plugin::Build::Autoconf>

=item L<alienfile>

=back

=cut

sub init
{
  my($self, $meta) = @_;
  
  $meta->prop->{destdir} = 1;
  
  # TODO: set the makefile type ??
  # TODO: handle destdir on windows ??
  # TODO: set cmake as a share requires ??
}

1;
