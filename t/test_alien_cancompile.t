use Test2::V0;
use Test::Alien::CanCompile;
use ExtUtils::CBuilder;

plan 1;

my $have_compiler = ExtUtils::CBuilder->new->have_compiler;

ok $have_compiler;
