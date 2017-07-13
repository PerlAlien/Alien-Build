use strict;
use warnings;

print "package is @{[ __PACKAGE__ ]}\n";

logx "hey";

our $run_basic_pl;

$run_basic_pl = 1;

preload 'Foo::Bar';
postload 'Baz::Frooble';

1;
