#!/usr/bin/env perl

use strict;
use warnings;
use Alien::Build;
use Path::Tiny qw( path );
use Alien::Build::Util qw( _mirror );
use YAML qw( Dump );

unless(defined $ENV{ALIEN_PREFIX})
{
  print STDERR "please set ALIEN_PREFIX to the install location!\n";
  exit 2;
}

my $prefix = path($ENV{ALIEN_PREFIX})->absolute;
my $alienfile = shift @ARGV;

unless(defined $alienfile)
{
  print STDERR "usage: $0 file.alienfile\n";
  exit 2;
}

$alienfile = path( $alienfile );

my($name) = $alienfile->basename =~ /^(.*)\.alienfile$/;

if($alienfile->basename eq 'alienfile')
{
  $name = $alienfile->parent->basename;
  $name =~ s/^Alien-//;
}

unless($name)
{
  print STDERR "please provide an alienfile\n";
  exit 2;
}

my $example = path(__FILE__)->parent->absolute;

my $build = Alien::Build->load("$alienfile",
  root => $example->child('_alien')->stringify,
);

$build->load_requires('configure');
$build->set_prefix($prefix->child("perl/lib/share/Alien-$name")->absolute->stringify);
$build->set_stage($example->child("blib/lib/auto/share/Alien-$name")->absolute->stringify);
$build->load_requires($build->install_type);
$build->download;
$build->build;

if($build->install_type eq 'share'){
  path($build->runtime_prop->{prefix})->mkpath;
  
  _mirror(
    $build->install_prop->{stage},
    $build->runtime_prop->{prefix},
    { verbose => 1 },
  );
}

print Dump($build->runtime_prop);
