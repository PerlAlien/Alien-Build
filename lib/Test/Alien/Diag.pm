package Test::Alien::Diag;

use strict;
use warnings;
use 5.008004;
use Test2::API qw( context );
use Exporter qw( import );

our @EXPORT = qw( alien_diag );
our @EXPORT_OK = @EXPORT;

# ABSTRACT: Print out standard diagnostic for Aliens in the test step.
# VERSION

=head1 SYNOPSIS

 use Test2::V0;
 use Test::Alien::Diag qw( alien_diag );

=head1 DESCRIPTION

This module provides an C<alien_diag> method that prints out diagnostics useful for
cpantesters and other bug reports that gives a quick summary of the important settings
like C<clfags> and C<libs>.

=head1 FUNCTIONS

=head2 alien_diag

 alien_diag @aliens;

prints out diagnostics for each given alien.  Each alien must be the class
name of an alien.

[version 2.68]

 alien_diag @aliens, \%options;

Starting with L<Alien::Build> 2.68, you can provide an option hash to adjust the
behavior of C<alien_diag>.  Valid options are:

=over 4

=item properties

Additional properties to display in the diagnostic.  Useful when you have an L<Alien>
with custom properties defined in the subclass.

=item list_properties

Additional properties that are returned as a list to display in the diagnostic.  Useful
when you have an L<Alien> with customer properties that return a list.

=back

=cut

my @default_scalar_properties = qw(
  cflags cflags_static libs libs_static version install_type
);

my @default_list_properties = qw(
  dynamic_libs bin_dir
);

sub alien_diag ($@)
{
  my $ctx = context();

  my %options = defined $_[-1] && ref($_[-1]) eq 'HASH' ?  %{ pop @_ } : ();

  my @extra_properties      = @{ delete $options{properties}      || [] };
  my @extra_list_properties = @{ delete $options{list_properties} || [] };

  my $max = 0;
  foreach my $alien (@_)
  {
    foreach my $name (@default_scalar_properties, @default_list_properties, @extra_properties, @extra_list_properties)
    {
      if(eval { $alien->can($name) })
      {
        my $str = "$alien->$name";
        if(length($str) > $max)
        {
          $max = length($str);
        }
      }
    }
  }


  $ctx->diag('');

  if(%options)
  {
    my @extra = sort keys %options;
    $ctx->diag("warning: unknown option@{[ @extra > 1 ? 's' : '' ]} for alien_diag: @extra");
    $ctx->diag("(you should check for typos or maybe upgrade to a newer version of Alien::Build)");
  }


  foreach my $alien (@_) {
    $ctx->diag('') for 1..2;

    my $found = 0;

    foreach my $name (sort(@default_scalar_properties, @extra_properties))
    {
      if(eval { $alien->can($name) })
      {
        $found++;
        my $value = $alien->$name;
        $value = '[undef]' unless defined $value;
        $ctx->diag(sprintf "%-${max}s = %s", "$alien->$name", $value);
      }
    }

    foreach my $name (sort(@default_list_properties, @extra_list_properties))
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
  }

  $ctx->diag('') for 1..2;

  $ctx->release;
}

1;
