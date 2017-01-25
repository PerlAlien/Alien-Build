package Alien::Build::Plugin::NesAdvantage::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;

sub init
{
  my($self, $meta) = @_;
  $meta->prop->{nesadvantage} = 'negotiate';
}

1;
