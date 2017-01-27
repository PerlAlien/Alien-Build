package Alien::Build::Plugin::Build::MSYS;

use strict;
use warnings;
use Alien::Build::Plugin;
use constant _win => $^O eq 'MSWin32';

# ABSTRACT: MSYS plugin for Alien::Build
# VERSION

sub init
{
  my($self, $meta) = @_;
  
  if($^O eq 'MSWin32')
  {
    $meta->add_requires('share' => 'Alien::MSYS' => '0.07');
  }

=head1 HELPERS

=head2 make

 %{make}

On windows the default C<%{make}> helper is replace with the make that comes with
L<Alien::MSYS>.  This is almost certainly what you want, as most unix style make
projects will not build with C<nmake> or C<dmake> typically used by Perl on Windows.

=cut
  
  # if we are building something with autoconf, the gmake that comes with
  # Alien::MSYS is almost certainly preferable to the nmake or dmake that
  # was used to build Perl
  $meta->interpolator->replace_helper(
    make => sub { 'make' },
    'Alien::MSYS' => '0.07'
  ) if $^O eq 'MSWin32';
  
  $self;
}

1;
