use Test2::V0 -no_srand => 1;
use Test::Alien::CanCompile;
use ExtUtils::CBuilder;

my $have_compiler = ExtUtils::CBuilder->new->have_compiler;

ok $have_compiler;

done_testing;
