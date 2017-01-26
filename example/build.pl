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

my $build = Alien::Build->load("$alienfile");

if($build->meta_prop->{destdir})
{
  print "$name using DESTDIR\n";
  $build->install_prop->{prefix} = $prefix->child("perl/lib/share/Alien-$name")->absolute->stringify;
  $build->install_prop->{stage}  = path("blib/lib/auto/share/Alien-$name")->absolute->stringify;
  $build->runtime_prop->{prefix} = $prefix->child("perl/lib/share/Alien-$name")->absolute->stringify;
}
else
{
  print "$name using direct install\n";
}

$build->load_requires('any');

if($build->install_type eq 'share')
{
  $build->load_requires('share');
  $build->download;
  $build->build;

  path($build->runtime_prop->{prefix})->mkpath;
  
  _mirror(
    $build->install_prop->{stage},
    $build->runtime_prop->{prefix},
    { verbose => 1 },
  );
}

elsif($build->install_type eq 'system')
{
  $build->load_requires('system');
  $build->gather_system;
}

print Dump($build->runtime_prop);
