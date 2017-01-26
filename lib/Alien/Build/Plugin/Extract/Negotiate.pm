package Alien::Build::Plugin::Extract::Negotiate;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Extraction negotiation plugin
# VERSION

has '+format' => 'tar';

sub init
{
  my($self, $meta) = @_;
  
  my $format = $self->format;
  $format = 'tar.gz'  if $format eq 'tgz';
  $format = 'tar.bz2' if $format eq 'tbz';
  $format = 'tar.xz'  if $format eq 'txz';
  
  my $extract;
  
  if($format =~ /^tar(|\.gz|\.bz2)$/)
  {
    $extract = 'ArchiveTar';
  }
  elsif($format eq 'zip')
  {
    $extract = 'ArchiveZip';
  }
  elsif($format eq 'tar.xz')
  {
    $extract = 'CommandLine';
  }
  elsif($format eq 'd')
  {
    $extract = 'Directory';
  }
  else
  {
    die "do not know how to handle format: $format";
  }
  
  $self->_plugin($meta, 'Extract', $extract, format => $format);
}

sub _plugin
{
  my($self, $meta, $type, $name, @args) = @_;
  my $class = "Alien::Build::Plugin::${type}::$name";
  my $pm    = "Alien/Build/Plugin/$type/$name.pm";
  require $pm;
  my $plugin = $class->new(@args);
  $plugin->init($meta); 
}

1;
