package Test2::Tools::Curl;

use strict;
use warnings;
use Test2::API qw( context );
use Path::Tiny qw( path );
use base qw( Exporter );

our @EXPORT = qw( capture_note test_config );

sub capture_note (&)
{
  my($code) = @_;
  my($out, $error, @ret) = Capture::Tiny::capture_merged(sub { my @ret = eval { $code->() }; ($@, @ret) });
  
  my $ctx = context();
  $ctx->note($out) if $out ne '';
  $ctx->release;
  
  die $error if $error;
  wantarray ? @ret : $ret[0];
}

sub test_config ($)
{
  my($name) = @_;
  my $path = path("t/bin/$name.json");
  
  if(-f $path)
  {
    my $config = JSON::PP::decode_json(scalar $path->slurp);
    return $config;
  }
  eles
  {
    return;
  }
}

1;
