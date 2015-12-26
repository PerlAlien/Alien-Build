package Test::Alien::Synthetic;

use strict;
use warnings;
use Test::Stream::Context qw( context );

# ABSTRACT: A mock alien object for testing
# VERSION

=head1 SYNOPSIS

 use Test::Stream -V1;
 use Test::Alien;
 
 plan 1;
 
 my $alien = synthetic {
   cflags => '-I/foo/bar/include',
   libs   => '-L/foo/bar/lib -lbaz',
 };
 
 alien_ok $alien;

=head1 DESCRIPTION

This class is used to model a synthetic L<Alien>
class that implements the minimum L<Alien::Base>
interface needed by L<Test::Alien>.

It can be useful if you have a non-L<Alien::Base>
based L<Alien> distribution that you need to test.

=head1 ATTRIBUTES

=head2 cflags

String containing the compiler flags

=head2 libs

String containing the linker and library flags

=head2 dynamic_libs

List reference containing the dynamic libraries.

=head2 bin_dir

Tool binary directory.

=cut

sub _def ($) { my($val) = @_; defined $val ? $val : '' }

sub cflags       { _def shift->{cflags}             }
sub libs         { _def shift->{libs}               }
sub dynamic_libs { @{ shift->{dynamic_libs} || [] } }

sub bin_dir
{
  my $dir = shift->{bin_dir};
  defined $dir && -d $dir ? ($dir) : ();
}

1;
