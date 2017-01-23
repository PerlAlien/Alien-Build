package Alien::Build::Plugin::Build::MSYS;

use strict;
use warnings;
use Alien::Build::Plugin;
use constant _win => $^O eq 'MSWin32';

# ABSTRACT: MSYS plugin for Alien::Build
# VERSION

sub init
{
  my($self, $meta) = @_;
  
  if($^O eq 'MSWin32')
  {
    $meta->add_requires('share' => 'Alien::MSYS' => '0.07');
  }

  $self;
}

1;
