package Test::Alien;

use strict;
use warnings;
use 5.008001;
use Test::Stream::Context qw( context );
use Test::Stream::Exporter;
default_exports qw( alien_ok );
no Test::Stream::Exporter;

# ABSTRACT: Testing tools for Alien modules
# VERSION

=head1 FUNCTIONS

=head2 alien_ok

 alien_ok $alien, $message;
 alien_ok $alien;

Load the given L<Alien> instance or class.  Checks that the instance or class conforms to the same
interface as L<Alien::Base>.  Will be used by subsequent tests.

=cut

my @aliens;

sub alien_ok ($;$)
{
  my($alien, $message) = @_;

  my $name = ref $alien ? ref($alien) . '[instance]' : $alien;
  
  my @methods = qw( dist_dir cflags libs install_type config dynamic_libs bin_dir alien_helper );
  $message ||= "$name responds to: @methods";
  my @missing = grep { ! $alien->can($_) } @methods;
  
  my $ok = !@missing;
  my $ctx = context();
  $ctx->ok($ok, $message);
  $ctx->diag("  missing method $_") for @missing;
  $ctx->release;
  
  push @aliens, $alien if $ok;
  
  $ok;
}

1;
