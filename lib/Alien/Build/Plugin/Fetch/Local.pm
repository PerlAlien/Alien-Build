package Alien::Build::Plugin::Fetch::Local;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::chdir;
use Path::Tiny ();

# ABSTRACT: Local file plugin for fetching files
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Fetch::Local' => (
   url => 'patch/libfoo-1.00.tar.gz',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This fetch plugin fetches files from the local file system.  It is mostly useful if you
intend to bundle packages with your Alien.

=head1 PROPERTIES

=head2 url

The initial URL to fetch.  This may be a C<file://> style URL, or just the path on the
local system.

=cut

has url => 'patch';

=head2 root

The directory from which the URL should be relative.  The default is usually reasonable.

=cut

has root => undef;

sub init
{
  my($self, $meta) = @_;
    
  if($self->url =~ /^file:/)
  {
    $meta->add_requires('share' => 'URI' => 0 );
    $meta->add_requires('share' => 'URI::file' => 0 );
  }

  {
    my $root = $self->root;
    if(defined $root)
    {
      $root = Path::Tiny->new($root)->absolute->stringify;
    }
    else
    {
      $root = "$CWD";
    }
    $self->root($root);
  }
  
  $meta->register_hook( fetch => sub {
    my(undef, $path) = @_;
    
    $path ||= $self->url;
    
    if($path =~ /^file:/)
    {
      $DB::single = 1;
      my $root = URI::file->new($self->root);
      my $url = URI->new_abs($path, $root);
      $path = $url->path;
      $path =~ s{^/([a-z]:)}{$1}i if $^O eq 'MSWin32';
    }
    
    $path = Path::Tiny->new($path)->absolute($self->root);
    
    if(-d $path)
    {
      return {
        type => 'list',
        list => [
          map { { filename => $_->basename, url => $_->stringify } } 
          sort { $a->basename cmp $b->basename } $path->children,
        ],
      };
    }
    elsif(-f $path)
    {
      return {
        type     => 'file',
        filename => $path->basename,
        path     => $path->stringify,
      };
    }
    else
    {
      die "no such file or directory $path";
    }
    
    
  });
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Download::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut

