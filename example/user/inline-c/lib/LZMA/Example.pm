package LZMA::Example;

use strict;
use warnings;
use Inline with => 'Alien::xz';
use Inline C => <<'END';
#include <lzma.h>
const char * _version_string()
{
  return lzma_version_string();
}
END
use Exporter qw( import );

our $VERSION = '0.01';
our @EXPORT = qw( lzma_version_string );

sub lzma_version_string
{
  _version_string();
}

1;
