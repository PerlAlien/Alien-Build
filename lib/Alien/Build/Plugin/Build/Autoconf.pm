package Alien::Build::Plugin::Build::Autoconf;

use strict;
use warnings;
use Alien::Build::Plugin;
use constant _win => $^O eq 'MSWin32';

# ABSTRACT: Autoconf plugin for Alien::Build
# VERSION

has with_pic       => 1;
has dynamic        => 0;

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
  #  - --disable-shared on by default
  #  - AB::P::Autoconf::Shared to build shared library too

  my @msys_reqs = $^O eq 'MSWin32' ? ('Alien::MSYS' => '0.07') : ();

  $intr->add_helper(
    configure => sub {
      my $configure = _win ? 'sh configure' : './configure';
      $configure .= ' --with-pic' if $self->with_pic;
      $configure;
    },
    @msys_reqs,
  );
  
  $meta->default_hook(
    build => [
      '%{configure} --prefix=%{alien.runtime.prefix} --disable-shared',
      '%{make}',
      '%{make} install',
    ]
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
