package Alien::Build::Plugin::RogerRamjet;

use strict;
use warnings;
use Alien::Build::Plugin;

has 'foo'  => 22;
has '+bar' => sub { 'something generated' };

1;
