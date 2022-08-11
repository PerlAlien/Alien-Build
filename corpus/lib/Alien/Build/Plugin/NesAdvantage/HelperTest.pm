package Alien::Build::Plugin::NesAdvantage::HelperTest;

use strict;
use warnings;
use Alien::Build::Plugin;

sub init
{
  my($self, $meta) = @_;
  my $intr = $meta->interpolator;
  $intr->replace_helper('nes' => sub { 'advantage' });
}

1;
