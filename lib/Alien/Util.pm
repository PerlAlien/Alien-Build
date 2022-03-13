package Alien::Util;

use strict;
use warnings;
use Exporter qw( import );

# ABSTRACT: Alien Utilities used at build and runtime
# VERSION

=head1 SYNOPSIS

 use Alien::Util qw( version_cmp );

=head1 DESCRIPTION

This module contains some functions used by both the L<Alien::Build> build-time and <Alien::Base>
run-time for Alien.

=cut

our @EXPORT_OK = qw( version_cmp );

=head2 version_cmp

  $cmp = version_cmp($x, $y)

Comparison method used by L<atleast_version>, L<exact_version> and
L<max_version>. May be useful to implement custom comparisons, or for
subclasses to overload to get different version comparison semantics than the
default rules, for packages that have some other rules than the F<pkg-config>
behaviour.

Should return a number less than, equal to, or greater than zero; similar in
behaviour to the C<< <=> >> and C<cmp> operators.

=cut

# Sort::Versions isn't quite the same algorithm because it differs in
# behaviour with leading zeroes.
#   See also  https://dev.gentoo.org/~mgorny/pkg-config-spec.html#version-comparison
sub version_cmp {
  my @x = (shift =~ m/([0-9]+|[a-z]+)/ig);
  my @y = (shift =~ m/([0-9]+|[a-z]+)/ig);

  while(@x and @y) {
    my $x = shift @x; my $x_isnum = $x =~ m/[0-9]/;
    my $y = shift @y; my $y_isnum = $y =~ m/[0-9]/;

    if($x_isnum and $y_isnum) {
      # Numerical comparison
      return $x <=> $y if $x != $y;
    }
    elsif(!$x_isnum && !$y_isnum) {
      # Alphabetic comparison
      return $x cmp $y if $x ne $y;
    }
    else {
      # Of differing types, the numeric one is newer
      return $x_isnum - $y_isnum;
    }
  }

  # Equal so far; the longer is newer
  return @x <=> @y;
}

1;

=head1 SEE ALSO

L<Alien::Base>, L<alienfile>, L<Alien::Build>

=cut
