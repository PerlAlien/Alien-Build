package Alien::Build::Plugin::Build::Autoconf;

use strict;
use warnings;
use Alien::Build::Plugin;
use Env qw( @PATH );
use constant _win => $^O eq 'MSWin32';

# ABSTRACT: Autoconf plugin for Alien::Build
# VERSION

has with_pic       => 1;
has dynamic        => 0;

sub init
{
  my($self, $meta) = @_;
  
  $meta->prop->{destdir} = 1;
  $meta->prop->{autoconf} = 1;
  
  my $intr = $meta->interpolator;

  $meta->around_hook(
    build => sub {
      my $orig = shift;
      my $build = shift;

      my $prefix = $build->install_prop->{prefix};
      $prefix =~ s!^([a-z]):!/$1!i if _win;
      $build->install_prop->{autoconf_prefix} = $prefix;

      local $ENV{PATH} = $ENV{PATH};
      if(_win)
      {
        unshift @PATH, Alien::MSYS::msys_path();
      }

      $orig->($build, @_);
    },
  );

=head1 HELPERS

=head2 configure

 %{configure}

The correct incantation to start an autoconf style C<configure> script on your platform.
Some reasonable default flags will be provided.

=cut

  # TODO:
  #  - AB::P::Autoconf::Shared to build shared library too

  my @msys_reqs = _win ? ('Alien::MSYS' => '0.07') : ();

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
      '%{configure} --prefix=%{alien.install.autoconf_prefix} --disable-shared',
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
  ) if _win;
  
  $self;
}

1;
