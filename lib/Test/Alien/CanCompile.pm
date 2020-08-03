package Test::Alien::CanCompile;

use strict;
use warnings;
use 5.008004;
use Test2::API qw( context );

# ABSTRACT: Skip a test file unless a C compiler is available
# VERSION

=head1 SYNOPSIS

 use Test::Alien::CanCompile;

=head1 DESCRIPTION

This is just a L<Test2> plugin that requires that a compiler
be available.  Otherwise the test will be skipped.

=cut

sub skip
{
  require ExtUtils::CBuilder;
  ExtUtils::CBuilder->new->have_compiler ? undef : 'This test requires a compiler.';
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

=back

=cut
