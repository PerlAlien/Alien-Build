package LZMA::Example;

use strict;
use warnings;
use base qw( Exporter );

our $VERSION = '0.01';
our @EXPORT = qw( lzma_version_string );

require XSLoader;
XSLoader::load('LZMA::Example', $VERSION);

1;
