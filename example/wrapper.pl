use strict;
use warnings;
use YAML qw( Dump );
use Alien::Base::Wrapper ();

# Print out the Module::Build and ExtUtils::MakeMaker
# for a list of aliens, using Alien::Base::Wrapper

Alien::Base::Wrapper->import(@ARGV, '!export');

print Dump(
  mb => [Alien::Base::Wrapper->mb_args],
  mm => [Alien::Base::Wrapper->mm_args],
);


