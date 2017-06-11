package LZMA::Example;

use strict;
use warnings;
use FFI::Platypus;
use Alien::xz;
use base qw( Exporter );

our $VERSION = '0.01';
our @EXPORT = qw( lzma_version_string );

my $ffi = FFI::Platypus->new(
  lib => [ Alien::xz->dynamic_libs ],
);

$ffi->attach( lzma_version_string => [] => 'string' );

1;
