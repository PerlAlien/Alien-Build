package Test::Alien::Diag;

use strict;
use warnings;
use Test2::API qw( context );
use base qw( Exporter );

our @EXPORT = qw( alien_diag );
our @EXPORT_OK = @EXPORT;

# ABSTRACT: Print out standard diagnostic for Aliens in the test step.
# VERSION

=head1 SYNOPSIS

 use Test2::V0;
 use Test::Alien::Diag qw( alien_diag );

=head1 DESCRIPTION

This module provides an C<alien_diag> method that prints out diagnostics useful for
cpantesters for other bug reports that gives a quick summary of the important settings
like C<clfags> and C<libs>.

=head1 FUNCTIONS

=head2 alien_diag

 alien_diag $alien;

prints out diagnostics.

=cut

sub alien_diag ($@)
{
  my $ctx = context();

  my $max = 0;
  foreach my $alien (@_)
  {
    foreach my $name (qw( cflags cflags_static libs libs_static version install_type dynamic_libs bin_dir ))
    {
      my $str = "$alien->$name";
      if(length($str) > $max)
      {
        $max = length($str);
      }
    }
  }


  $ctx->diag('');
  foreach my $alien (@_) {
    $ctx->diag('') for 1..2;

    my $found = 0;

    foreach my $name (qw( cflags cflags_static libs libs_static version install_type ))
    {
      if(eval { $alien->can($name) })
      {
        $found++;
        $ctx->diag(sprintf "%-${max}s = %s", "$alien->$name", $alien->$name);
      }
    }

    foreach my $name (qw( dynamic_libs bin_dir ))
    {
      if(eval { $alien->can($name) })
      {
        $found++;
        my @list = eval { $alien->$name };
        next if $@;
        $ctx->diag(sprintf "%-${max}s = %s", "$alien->$name", $_) for @list;
      }
    }

    $ctx->diag("no diagnostics found for $alien") unless $found;

    $ctx->diag('') for 1..2;
  }

  $ctx->release;
}

1;
