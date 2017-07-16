package Alien::Build::Plugin::Core::Download;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();
use Alien::Build::Util qw( _mirror );

# ABSTRACT: Core download plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin does some core download logic.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub _hook
{
  my($build) = @_;

  my $res = $build->fetch;

  if($res->{type} =~ /^(?:html|dir_listing)$/)
  {
    my $type = $res->{type};
    $type =~ s/_/ /;
    $build->log("decoding $type");
    $res = $build->decode($res);
  }

  if($res->{type} eq 'list')
  {
    $res = $build->prefer($res);
    die "no matching files in listing" if @{ $res->{list} } == 0;
    my $version = $res->{list}->[0]->{version};
    my($pick, @other) = map { $_->{url} } @{ $res->{list} };
    if(@other > 8)
    {
      splice @other, 7;
      push @other, '...';
    }
    $build->log("candidate *$pick");
    $build->log("candidate  $_") for @other;
    $res = $build->fetch($pick);

    if($version)
    {
      $version =~ s/\.+$//;
      $build->log("setting version based on archive to $version");
      $build->runtime_prop->{version} = $version;
    }
  }

  my $tmp = Alien::Build::TempDir->new($build, "download");

  if($res->{type} eq 'file')
  {
    my $alienfile = $res->{filename};
    $build->log("downloaded $alienfile");
    if($res->{content})
    {
      my $path = Path::Tiny->new("$tmp/$alienfile");
      $path->spew_raw($res->{content});
      $build->install_prop->{download} = $path->stringify;
      $build->install_prop->{complete}->{download} = 1;
      return $build;
    }
    elsif($res->{path})
    {
      my $from = Path::Tiny->new($res->{path});
      my $to   = Path::Tiny->new("$tmp/@{[ $from->basename ]}");
      if(-d $res->{path})
      {
        _mirror $from, $to;
      }
      else
      {
        require File::Copy;
        File::Copy::copy(
          "$from" => "$to",
        ) || die "copy $from => $to failed: $!";
      }
      $build->install_prop->{download} = $to->stringify;
      $build->install_prop->{complete}->{download} = 1;
      return $build;
    }
    die "file without content or path";
  }
  die "unknown fetch response type: @{[ $res->{type} ]}";
}

sub init
{
  my($self, $meta) = @_;

  $meta->default_hook(download => \&_hook);
}

1;
