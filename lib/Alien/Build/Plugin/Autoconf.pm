package Alien::Build::Plugin::Autoconf;

use strict;
use warnings;
use Alien::Build::Plugin;
use constant _win => $^O eq 'MSWin32';

# ABSTRACT: Autoconf plugin for Alien::Build
# VERSION


sub init
{
  my($self, $meta) = @_;
  
  my $intr = $meta->interpolator;

=head1 HELPERS

=head2 configure

 %{configure}

The correct incantation to start an autoconf style C<configure> script on your platform.
Some reasonable default flags will be provided.

=cut

  # TODO:
  #  - --with-pic       on by default
  #  - --disable-shared on by default
  #  - AB::P::Autoconf::Shared to build shared library too

  my @msys_reqs = $^O eq 'MSWin32' ? ('Alien::MSYS' => '0.07') : ();

  $intr->add_helper(
    configure => sub {
      _win ? 'sh configure' : './configure'
    },
    @msys_reqs,
  );

=head2 make

 %{make}

On windows the default C<%{make}> helper is replace with the make that comes with
L<Alien::MSYS>.  This is almost certainly what you want, as most autoconf projects
will not build with C<nmake> or C<dmake> typically used by Perl on Windows.

=cut
  
  # if we are building something with autoconf, the gmake that comes with
  # Alien::MSYS is almost certainly preferable to the nmake or dmake that
  # was used to build Perl
  $intr->replace_helper(
    make => sub { 'make' },
    @msys_reqs,
  ) if $^O eq 'MSWin32';
  
  $self;
}

1;
