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

=cut

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('share' => 'Alien::Build::Plugin::Gather::IsolateDynamic' => '0.42' );
  
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
