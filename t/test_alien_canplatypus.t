use Test2::V0;
use Test::Alien::CanPlatypus;
use ExtUtils::CBuilder;

plan 1;

my $have_platypus = eval { require FFI::Platypus; 1 };

ok $have_platypus;
