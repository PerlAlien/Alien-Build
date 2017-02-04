package Alien::Build::Plugin::Core::Gather;

use strict;
use warnings;
use Alien::Build::Plugin;
use Env qw( @PATH @PKG_CONFIG_PATH );
use Path::Tiny ();
use File::chdir;
use Alien::Build::Util qw( _mirror _destdir_prefix );
use JSON::PP ();

# ABSTRACT: Core gather plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin helps make the gather stage work.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->default_hook(
    $_ => sub {},
  ) for qw( gather_system gather_share );


  $meta->around_hook(
    gather_share => sub {
      my($orig, $build) = @_;
      
      local $ENV{PATH} = $ENV{PATH};
      local $ENV{PKG_CONFIG_PATH} = $ENV{PKG_CONFIG_PATH};
      unshift @PATH, Path::Tiny->new('bin')->absolute->stringify
        if -d 'bin';
      unshift @PKG_CONFIG_PATH, Path::Tiny->new('lib/pkgconfig')->absolute->stringify
        if -d 'lib/pkgconfig';
        
      if($build->meta_prop->{destdir})
      {
        my $destdir = $ENV{DESTDIR};
        die "nothing was installed into destdir" unless -d $destdir;
        my $src = Path::Tiny->new(_destdir_prefix($ENV{DESTDIR}, $build->install_prop->{prefix}));
        my $dst = Path::Tiny->new($build->install_prop->{stage});
        
        my $res = do {
          local $CWD = "$src";
          $orig->($build);
        };
        
        $dst->mkpath;
        _mirror("$src", "$dst", {
          verbose => 1,
          filter => $build->meta_prop->{destdir_filter},
        });
        
        return $res;
      }
      else
      {
        local $CWD = $build->install_prop->{stage};
        return $orig->($build);
      }
    }
  );
  
  $meta->around_hook(
    $_ => sub {
      my($orig, $build) = @_;
      
      my $res = $orig->($build);

      die "stage is not defined.  be sure to call set_stage on your Alien::Build instance"
        unless $build->install_prop->{stage};
      
      my $stage = Path::Tiny->new($build->install_prop->{stage});
      $stage->child('_alien')->mkpath;
      
      # drop a alien.json file for the runtime properties
      $stage->child('_alien/alien.json')->spew(
        JSON::PP->new->pretty->encode($build->runtime_prop)
      );
      
      # copy the alienfile, if we managed to keep it around.
      if($build->meta->filename      && 
         -r $build->meta->filename   &&
         $build->meta->filename !~ /\.(pm|pl)$/)
      {
        Path::Tiny->new($build->meta->filename)
                  ->copy($stage->child('_alien/alienfile'));
      }
      
      $res;
      
    },
  ) for qw( gather_share gather_system );
}

1;
