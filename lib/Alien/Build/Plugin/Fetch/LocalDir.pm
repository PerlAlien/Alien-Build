package Alien::Build::Plugin::Fetch::LocalDir;

use strict;
use warnings;
use Alien::Build::Plugin;
use File::chdir;
use Path::Tiny ();

# ABSTRACT: Local directory plugin for fetching files
# VERSION

=head1 SYNOPSIS

 use alienfile;
 share {
   start_url 'patch/libfoo-1.00/';
   plugin 'Fetch::LocalDir';
 };

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Download::Negotiate>
instead.  It picks the appropriate fetch plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This fetch plugin fetches files from the local file system.  It is mostly useful if you
intend to bundle source with your Alien.  If you are bundling tarballs see
L<Alien::Build::Plugin::Fetch::Local>.

=head1 PROPERTIES

=head2 root

The directory from which the start URL should be relative.  The default is usually reasonable.

=cut

has root => undef;

=head2 ssl

This property is for compatibility with other fetch plugins, but is not used.

=cut

has ssl => 0;

sub init
{
  my($self, $meta) = @_;

  my $url = $meta->prop->{start_url} || 'patch';

  $meta->add_requires('configure' => 'Alien::Build::Plugin::Fetch::LocalDir' => '0.72' );

  if($url =~ /^file:/)
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

  $meta->register_hook(
    fetch => sub {
      my($build, $path) = @_;

      $path ||= $url;

      if($path =~ /^file:/)
      {
        my $root = URI::file->new($self->root);
        my $url  = URI->new_abs($path, $root);
        $path = $url->path;
        $path =~ s{^/([a-z]:)}{$1}i if $^O eq 'MSWin32';
      }

      $path = Path::Tiny->new($path)->absolute($self->root);

      if(-d $path)
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
        $build->log("path $path is not a directory");
        $build->log("(you specified $url with root @{[ $self->root ]})");
        die "$path is not a directory";
      }
    }
  );
}

1;

=head1 SEE ALSO

=over 4

=item L<Alien::Build::Plugin::Download::Negotiate>

=item L<Alien::Build::Plugin::Fetch::Local>

=item L<Alien::Build>

=item L<alienfile>

=item L<Alien::Build::MM>

=item L<Alien>

=back

=cut

