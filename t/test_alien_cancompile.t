use strict;
use warnings;
use Test2::Bundle::Extended;
use Test::Alien::CanCompile;
use ExtUtils::CBuilder;

plan 1;

my $have_compiler = ExtUtils::CBuilder->new->have_compiler;

ok $have_compiler;
