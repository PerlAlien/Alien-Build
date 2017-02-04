package MyTest;

use strict;
use warnings;
use Path::Tiny qw( path );
use File::Temp qw( tempdir );
use base qw( Exporter );

our @EXPORT = qw( build_blank_alien_build alienfile path_to_tar );

delete $ENV{$_} for qw( ALIEN_BUILD_PRELOAD ALIEN_INSTALL_TYPE );

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

  my $tmp = path(tempdir( CLEANUP => 1 ));
  $build->set_stage($tmp->child('stage')->stringify);
  $build->set_prefix($tmp->child('prefix')->stringify);

  wantarray ? ($build, $meta) : $build;
}

sub alienfile
{
  my($str) = @_;
  my(undef, $filename, $line) = caller;
  $str = '# line '. $line . ' "' . $filename . qq("\n) . $str;
  my $alienfile = Path::Tiny->tempfile;
  $alienfile->spew($str);
  require Alien::Build;
  my $build = Alien::Build->load("$alienfile", root => tempdir(CLEANUP => 1));

  my $tmp = path(tempdir( CLEANUP => 1 ));
  $build->set_stage($tmp->child('stage')->stringify);
  $build->set_prefix($tmp->child('prefix')->stringify);

  $build;
}

sub path_to_tar
{
  require Alien::Build::Plugin::Extract::CommandLine;
  my $plugin = Alien::Build::Plugin::Extract::CommandLine->new;
  $plugin->tar_cmd;
}

1;
