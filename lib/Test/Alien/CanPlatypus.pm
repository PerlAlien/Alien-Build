package Test::Alien::CanPlatypus;

use strict;
use warnings;
use Test::Stream::Context qw( context );
use Test::Stream::Plugin;

# ABSTRACT: Skip a test file unless FFI::Platypus is available
# VERSION

=head1

 use Test::Alien::CanPlatypus;

=head1 DESCRIPTION

This is just a L<Test::Stream> plugin that requires that L<FFI::Platypus>
be available.  Otherwise the test will be skipped.

=cut
sub load_ts_plugin
{
  require ExtUtils::CBuilder;
  
  my $skip = ! eval { require FFI::Platypus; 1 };
  
  return unless $skip;

  my $ctx = context();
  $ctx->plan(0, "SKIP", "This test requires FFI::Platypus.");
  $ctx->release;
}

1;

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=cut
