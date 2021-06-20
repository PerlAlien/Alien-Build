package LZMA::Example;

use strict;
use warnings;
use Exporter qw( import );

our $VERSION = '0.01';
our @EXPORT = qw( lzma_version_string );

require XSLoader;
XSLoader::load('LZMA::Example', $VERSION);

1;
