package Test::Alien::Run;

use strict;
use warnings;

sub out    { shift->{out} }
sub err    { shift->{err} }
sub exit   { shift->{exit} }
sub signal { shift->{sig} }

1;
