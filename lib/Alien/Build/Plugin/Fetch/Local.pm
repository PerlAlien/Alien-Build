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
 meta->prop->{start_url} = 'patch/libfoo-1.00.tar.gz';
 plugin 'Fetch::Local';

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This fetch plugin fetches files from the local file system.  It is mostly useful if you
intend to bundle packages (as tarballs or zip files) with your Alien.  If you intend to
bundle a source tree, use L<Alien::Build::Plugin::Fetch::LocalDir>.

=head1 PROPERTIES

=head2 url

The initial URL to fetch.  This may be a C<file://> style URL, or just the path on the
local system.

=cut

has '+url' => '';

=head2 root

The directory from which the URL should be relative.  The default is usually reasonable.

=cut

has root => undef;

=head2 ssl

This property is for compatibility with other fetch plugins, but is not used.

=cut

has ssl => 0;

sub init
{
  my($self, $meta) = @_;
    
  $meta->prop->{start_url} ||= $self->url;
  $self->url($meta->prop->{start_url} || 'patch');

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
        tmp      => 0,
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

=over 4

=item L<Alien::Build::Plugin::Download::Negotiate>

=item L<Alien::Build::Plugin::Fetch::LocalDir>

=item L<Alien::Build>

=item L<alienfile>

=item L<Alien::Build::MM>

=item L<Alien>

=back

=cut

