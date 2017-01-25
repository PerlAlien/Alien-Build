package Alien::Build::Plugin::RogerRamjet;

use strict;
use warnings;
use Alien::Build::Plugin;

has 'foo'  => 22;
has '+bar' => sub { 'something generated' };
has 'baz'  => undef;

sub init
{
  my($self, $meta) = @_;
  
  $meta->prop->{ramjet} = 'roger';
  $meta->prop->{foo}    = $self->foo;
  $meta->prop->{bar}    = $self->bar;
  $meta->prop->{baz}    = $self->baz;
  
}

1;
