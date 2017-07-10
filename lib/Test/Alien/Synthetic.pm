package Test::Alien::Synthetic;

use strict;
use warnings;
use Test2::API qw( context );

# ABSTRACT: A mock alien object for testing
# VERSION

=head1 SYNOPSIS

 use Test2::V0;
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

B<NOTE>: The name of this class may move in the
future, so do not refer to this class name directly.
Instead create instances of this class using the
L<Test::Alien#synthetic> function.

=head1 ATTRIBUTES

=head2 cflags

String containing the compiler flags

=head2 cflags_static

String containing the static compiler flags

=head2 libs

String containing the linker and library flags

=head2 libs_static

String containing the static linker and library flags

=head2 dynamic_libs

List reference containing the dynamic libraries.

=head2 bin_dir

Tool binary directory.

=cut

sub _def ($) { my($val) = @_; defined $val ? $val : '' }

sub cflags       { _def shift->{cflags}             }
sub libs         { _def shift->{libs}               }
sub dynamic_libs { @{ shift->{dynamic_libs} || [] } }

sub cflags_static
{
  my($self) = @_;
  defined $self->{cflags_static}
    ? $self->{cflags_static}
    : $self->cflags;
}

sub libs_static
{
  my($self) = @_;
  defined $self->{libs_static}
    ? $self->{libs_static}
    : $self->libs;
}

sub bin_dir
{
  my $dir = shift->{bin_dir};
  defined $dir && -d $dir ? ($dir) : ();
}

1;

=head1 EXAMPLE

Here is a complete example using L<Alien::Libarchive> which is a non-L<Alien::Base>
based L<Alien> distribution.

 use strict;
 use warnings;
 use Test2::V0;
 use Test::Alien;
 use Alien::Libarchive;
 
 plan 5;
 
 my $real = Alien::Libarchive->new;
 my $alien = synthetic {
   cflags       => scalar $real->cflags,
   libs         => scalar $real->libs,
   dynamic_libs => [$real->dlls],
 };
 
 alien_ok $alien;
 
 xs_ok do { local $/; <DATA> }, with_subtest {
   my($module) = @_;
   plan 1;
   my $ptr = $module->archive_read_new;
   like $ptr, qr{^[0-9]+$};
   $module->archive_read_free($ptr);
 };
 
 ffi_ok { symbols => [qw( archive_read_new )] }, with_subtest {
   my($ffi) = @_;
   my $new  = $ffi->function(archive_read_new => [] => 'opaque');
   my $free = $ffi->function(archive_read_close => ['opaque'] => 'void');
   my $ptr = $new->();
   like $ptr, qr{^[0-9]+$};
   $free->($ptr);
 };
 
 __DATA__
 
 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 #include <archive.h>
 
 MODULE = TA_MODULE PACKAGE = TA_MODULE
 
 void *archive_read_new(class);
     const char *class;
   CODE:
     RETVAL = (void*) archive_read_new();
   OUTPUT:
     RETVAL
 
 void archive_read_free(class, ptr);
     const char *class;
     void *ptr;
   CODE:
     archive_read_free(ptr);

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=cut
