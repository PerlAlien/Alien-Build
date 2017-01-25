package alienfile;

use strict;
use warnings;
use Alien::Build;
use base qw( Exporter );

# ABSTRACT: Specification for defining an external dependency for CPAN
# VERSION

our @EXPORT = qw( requires on plugin probe share sys download fetch decode sort extract build gather );

=head1 DIRECTIVES

=head2 plugin

=cut

sub plugin
{
}

=head2 probe

=cut

sub probe
{
}

=head2 share

=cut

sub share (&)
{
}

=head2 sys

=cut

sub sys (&)
{
}

=head2 download

=cut

sub download
{
}

=head2 fetch

=cut

sub fetch
{
}

=head2 decode

=cut

sub decode
{
}

=head2 sort

=cut

# TODO: rename
sub sort
{
}

=head2 extract

=cut

sub extract
{
}

=head2 build

=cut

sub build
{
}

=head2 gather

=cut

sub gather
{
}

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
  $meta->add_requires($meta->{phase}, $module, $version);
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
  
  unless($phase =~ /^(?:any|share|system|configure)$/)
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

sub import
{
  strict->import;
  warnings->import;
  goto &Exporter::import;
}

1;
