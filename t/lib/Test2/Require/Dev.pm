package Test2::Require::Dev;

use strict;
use warnings;
use Path::Tiny qw( path );
use JSON::PP qw( decode_json );
use base qw( Test2::Require );

sub skip
{
  my $meta = path('META.json')->absolute;
  return undef unless -f $meta;
  $meta = decode_json($meta->slurp);
  return undef unless $meta->{release_status} eq 'stable';
  return 'Test runs only on development release';
}

1;
