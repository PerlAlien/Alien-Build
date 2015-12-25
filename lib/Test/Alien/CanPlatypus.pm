package Test::Alien::CanPlatypus;

use strict;
use warnings;
use Test::Stream::Context qw( context );
use Test::Stream::Plugin;

# ABSTRACT: Skip a test file unless FFI::Platypus is available
# VERSION

sub load_ts_plugin
{
  require ExtUtils::CBuilder;
  
  my $skip = ! eval { require FFI::Platypus; 1 };
  
  return unless $skip;

  my $ctx = context();
  $ctx->plan(0, "SKIP", "This test requires FFI::Platypus.");
  $ctx->release;
}

1;
