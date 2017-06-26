package Alien::Build::Plugin::Gather::IsolateDynamic;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();
use Alien::Build::Util qw( _destdir_prefix );
use File::Copy ();

# ABSTRACT: LWP plugin for fetching files
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Gather::IsolateDynamic';

=head1 DESCRIPTION

This plugin moves dynamic libraries from the C<lib> and C<bin> directories and puts them in
their own C<dynamic> directory.  This allows them to be used by FFI modules, but to be ignored
by XS modules.

This plugin provides the equivalent functionality of the C<alien_isolate_dynamic> attribute
from L<Alien::Base::ModuleBuild>.  

=cut

sub init
{
  my($self, $meta) = @_;

  # plugin was introduced in 0.42, but had a bug which was fixed in 0.48  
  $meta->add_requires('share' => 'Alien::Build::Plugin::Gather::IsolateDynamic' => '0.48' );
  
  $meta->after_hook(
    gather_share => sub {
      my($build) = @_;
      $build->log("Isolating dynamic libraries ...");

      my $install_root;
      if($build->meta_prop->{destdir})
      {
        my $destdir = $ENV{DESTDIR};
        $install_root = Path::Tiny->new(_destdir_prefix($ENV{DESTDIR}, $build->install_prop->{prefix}));
      }
      else
      {
        $install_root = Path::Tiny->new($build->install_prop->{stage});
      }

      foreach my $dir (map { $install_root->child($_) } qw( bin lib ))
      {
        next unless -d $dir;
        foreach my $from ($dir->children)
        {
          next unless $from->basename =~ /\.so/
          ||          $from->basename =~ /\.(dylib|bundle|la|dll|dll\.a)$/;
          my $to = $install_root->child('dynamic', $from->basename);
          $to->parent->mkpath;
          unlink "$to" if -e $to;
          $build->log("move @{[ $from->parent->basename ]}/@{[ $from->basename ]} => dynamic/@{[ $to->basename ]}");
          File::Copy::move("$from", "$to") || die "unable to move $from => $to $!";
        }
      }

      $build->log("                            Done!");
    },
  );
}

1;

=head1 SEE ALSO

L<Alien::Build>, L<alienfile>

=cut
