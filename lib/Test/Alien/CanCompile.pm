package Test::Alien::CanCompile;

use strict;
use warnings;
use Test::Stream::Context qw( context );
use Test::Stream::Plugin;

# ABSTRACT: Skip a test file unless a C compiler is available
# VERSION

sub load_ts_plugin
{
  require ExtUtils::CBuilder;
  
  my $skip = !ExtUtils::CBuilder->new->have_compiler;
  
  return unless $skip;

  my $ctx = context();
  $ctx->plan(0, "SKIP", "This test requires a compiler.");
  $ctx->release;
}

1;
