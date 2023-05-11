package LZMA::Example;

use strict;
use warnings;
use Capture::Tiny qw( capture );
use Alien::xz;
use Env qw( @PATH );
use Exporter qw( import );

our $VERSION = '0.01';
our @EXPORT = qw( lzma_version_string );

unshift @PATH, Alien::xz->bin_dir;

sub lzma_version_string
{
  my $out = capture { system 'xz', '--version' };
  my($version) = $out =~ /liblzma ([0-9.]+)/;
  $version;
}

1;
