package Alien::Build::Plugin::Download::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Download negotiation plugin
# VERSION

has '+url' => 'fixme';
has version => 'fixme';

sub init
{
  my($self, $meta) = @_;
}

1;
