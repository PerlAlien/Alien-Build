package alienfile;

use strict;
use warnings;
use Alien::Build;
use base qw( Exporter );

# ABSTRACT: Specification for defining an external dependency for CPAN
# VERSION

our @EXPORT = qw( requires on );

=head1 DIRECTIVES

=head2 requires

 requires $module;
 requires $module => $verson;

=cut

sub requires
{
  my($module, $version) = @_;
  $version ||= 0;
  my $caller = caller;
  my $meta = $caller->meta;
  $meta->add_requires($module, $version);
  ();
}

=head2 on

 on $phase => sub {
   requires $module;
   requires $module => $version;
 };

=cut

sub on
{
  my($phase, $code) = @_;
  
  unless($phase =~ /^(any|share|system)$/)
  {
    require Carp;
    Carp::croak "illegal phase: $phase";
  }
  
  my $caller = caller;
  my $meta = $caller->meta;
  local $meta->{phase} = $phase;
  $code->();
  ();
}

1;
