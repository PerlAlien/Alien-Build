package MyTest;

use strict;
use warnings;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
use base qw( Exporter );

our @EXPORT = qw( build_blank_alien_build );

sub build_blank_alien_build
{
  my $alienfile = path( tempdir( CLEANUP => 1 ) )->child('alienfile');
  $alienfile->touch;
  require Alien::Build;
  my $build = Alien::Build->load($alienfile);
  my $meta = $build->meta;
  wantarray ? ($build, $meta) : $build;
}

1;
