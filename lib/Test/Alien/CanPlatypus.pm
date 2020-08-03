package Test::Alien::CanPlatypus;

use strict;
use warnings;
use 5.008004;
use Test2::API qw( context );

# ABSTRACT: Skip a test file unless FFI::Platypus is available
# VERSION

=head1 SYNOPSIS

 use Test::Alien::CanPlatypus;

=head1 DESCRIPTION

This is just a L<Test2> plugin that requires that L<FFI::Platypus>
be available.  Otherwise the test will be skipped.

=cut

sub skip
{
  eval { require FFI::Platypus; 1 } ? undef : 'This test requires FFI::Platypus.';
}

sub import
{
  my $skip = __PACKAGE__->skip;
  return unless defined $skip;

  my $ctx = context();
  $ctx->plan(0, SKIP => $skip);
  $ctx->release;
}

1;

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=item L<FFI::Platypus>

=back

=cut
