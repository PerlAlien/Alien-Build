package Alien::Build::Plugin::Extract::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Extraction negotiation plugin
# VERSION

has '+format' => 'tar';

sub init
{
  my($self, $meta) = @_;
}

1;
