package MyTest::CaptureNote;

use strict;
use warnings;
use Test2::API qw( context );
use Capture::Tiny qw( capture_merged );
use Exporter qw( import );

our @EXPORT = qw( capture_note );

sub capture_note (&)
{
  my($code) = @_;
  my($out, $error, @ret) = Capture::Tiny::capture_merged(sub { my @ret = eval { $code->() }; ($@, @ret) });

  my $ctx = context();
  $ctx->note($out) if $out ne '';
  $ctx->release;

  die $error if $error;
  wantarray ? @ret : $ret[0];  ## no critic
}

1;
