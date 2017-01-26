package MyTest;

use strict;
use warnings;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
use base qw( Exporter );

our @EXPORT = qw( build_blank_alien_build alienfile );

sub build_blank_alien_build
{
  my(@args) = @_;
  my (undef, $name) = caller;
  if($name =~ /([a-z_]+)\.(t|pm|pl)$/i)
  {
    $name = $1;
  }
  else
  {
    $name = 'other';
  }
  
  my $dir = path(tempdir(CLEANUP => 1))->child($name);
  $dir->mkpath;
  
  my $alienfile = $dir->child("alienfile");
  $alienfile->touch;
  require Alien::Build;
  my $build = Alien::Build->load(
    $alienfile->stringify, 
    root => $dir->child('_alien')->stringify,
    @args,
  );
  my $meta = $build->meta;
  wantarray ? ($build, $meta) : $build;
}

sub alienfile
{
  my($str) = @_;
  my(undef, $filename, $line) = caller;
  $str = '# line '. $line . ' "' . $filename . qq("\n) . $str;
  my $alienfile = Path::Tiny->tempfile;
  $alienfile->spew($str);
  Alien::Build->load("$alienfile", root => tempdir(CLEANUP => 1));
}

1;
