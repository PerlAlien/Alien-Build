package Alien::Build::Log::Default;

use strict;
use warnings;
use 5.008001;
use base qw( Alien::Build::Log );

sub log
{
  my(undef, %args) = @_;
  my($message) = $args{message};
  my ($package, $filename, $line) = @{ $args{caller} };
  print "$package> $message\n";
}

1;
