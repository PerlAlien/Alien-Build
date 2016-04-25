package Test::Alien::CanPlatypus;

use strict;
use warnings;
use base 'Test2::Require';

# ABSTRACT: Skip a test file unless FFI::Platypus is available
# VERSION

=head1

 use Test::Alien::CanPlatypus;

=head1 DESCRIPTION

This is just a L<Test2> plugin that requires that L<FFI::Platypus>
be available.  Otherwise the test will be skipped.

=cut

sub skip
{
  eval { require FFI::Platypus; 1 } ? undef : 'This test requires FFI::Platypus.';
}

1;

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=cut
