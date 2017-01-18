package Alien::Build::Plugin::Autoconf;

use strict;
use warnings;
use base qw( Alien::Build::Plugin );
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
  #  - modify %{make} to be just 'make' on MSWin32 (since you will be using the Alien::MSYS verson);
  #  - AB::P::Autoconf::Shared to build shared library too

  $intr->add_helper(
    configure => sub {
      _win ? 'sh configure' : './configure'
    },
    ($^O eq 'MSWin32' ? ('Alien::MSYS' => '0.07') : ()),
  );
  
  $self;
}

1;
