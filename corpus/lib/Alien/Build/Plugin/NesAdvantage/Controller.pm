package Alien::Build::Plugin::NesAdvantage::Controller;

use strict;
use warnings;
use Alien::Build::Plugin;

sub init
{
  my($self, $meta) = @_;
  $meta->prop->{nesadvantage} = 'controller';
}

1;
