package Alien::Build::Plugin::Core::Download;

use strict;
use warnings;
use 5.008004;
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

    my @exclude;
    if($build->meta->prop->{start_url} =~ /^https:/)
    {
      @{ $res->{list} } = grep {
        $_->{url} =~ /https:/ ? 1 : do {
          push @exclude, $_->{url};
          0;
        }
      } @{ $res->{list} };
    }

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

    if(@exclude)
    {
      if(@exclude > 8)
      {
        splice @exclude, 7;
        push @exclude, '...';
      }
      $build->log("excluded insecure URLs:");
      $build->log($_) for @exclude;
    }

    $res = $build->fetch($pick);

    if($version)
    {
      $version =~ s/\.+$//;
      $build->log("setting version based on archive to $version");
      $build->runtime_prop->{version} = $version;
    }
  }

  if($res->{type} eq 'file')
  {
    my $alienfile = $res->{filename};
    $build->log("downloaded $alienfile");
    if($res->{content})
    {
      my $tmp = Alien::Build::TempDir->new($build, "download");
      my $path = Path::Tiny->new("$tmp/$alienfile");
      $path->spew_raw($res->{content});
      $build->install_prop->{download} = $path->stringify;
      $build->install_prop->{complete}->{download} = 1;
      return $build;
    }
    elsif($res->{path})
    {
      if(defined $res->{tmp} && !$res->{tmp})
      {
        if(-e $res->{path})
        {
          $build->install_prop->{download} = $res->{path};
          $build->install_prop->{complete}->{download} = 1;
        }
        else
        {
          die "not a file or directory: @{[ $res->{path} ]}";
        }
      }
      else
      {
        my $from = Path::Tiny->new($res->{path});
        my $tmp = Alien::Build::TempDir->new($build, "download");
        my $to   = Path::Tiny->new("$tmp/@{[ $from->basename ]}");
        if(-d $res->{path})
        {
          # Please note: _mirror and Alien::Build::Util are ONLY
          # allowed to be used by core plugins.  If you are writing
          # a non-core plugin it may be removed.  That is why it
          # is private.
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
      }
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
