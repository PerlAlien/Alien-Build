package Alien::Build::Plugin;

use strict;
use warnings;

# ABSTRACT: Plugin base class for Alien::Build
# VERSION

=head1 CONSTRUCTOR

=head2 new

 my $plugin = Alien::Build::Plugin->new;

=cut

sub new
{
  my($class) = @_;
  bless {}, $class;
}

=head1 METHODS

=head2 init

 $plugin->init($ab->meta); # $ab isa Alien::Build

=cut

sub init
{
  my($self) = @_;
  $self;
}

1;
