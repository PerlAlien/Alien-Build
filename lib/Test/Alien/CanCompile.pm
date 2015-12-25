package Test::Alien::CanCompile;

use strict;
use warnings;
use Test::Stream::Context qw( context );
use Test::Stream::Plugin;

# ABSTRACT: Skip a test file unless a C compiler is available
# VERSION

=head1

 use Test::Alien::CanCompile;

=head1 DESCRIPTION

This is just a L<Test::Stream> plugin that requires that a compiler
be available.  Otherwise the test will be skipped.

=cut

sub load_ts_plugin
{
  require ExtUtils::CBuilder;
  
  my $skip = !ExtUtils::CBuilder->new->have_compiler;
  
  return unless $skip;

  my $ctx = context();
  $ctx->plan(0, "SKIP", "This test requires a compiler.");
  $ctx->release;
}

1;

=head1 SEE ALSO

=over 4

=item L<Test::Alien>

=back

=cut
