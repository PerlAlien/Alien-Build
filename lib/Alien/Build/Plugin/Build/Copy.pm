package Alien::Build::Plugin::Build::Copy;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Autoconf plugin for Alien::Build
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Build::Copy';

=head1 DESCRIPTION

This plugin copies all of the files from the source to the staging prefix.
This is mainly useful for software packages that are provided as binary
blobs.  It works on both Unix and Windows using the appropriate commands
for those platforms without having worry about the platform details in your
L<alienfile>.

If you want to filter add or remove files from what gets installed you can
use a C<before> hook.

 build {
   ...
   before 'build' => sub {
     # remove or modify files
   };
   plugin 'Build::Copy';
   ...
 };

Some packages might have binary blobs on some platforms and require build
from source on others.  In that situation you can use C<if> statements
with the appropriate logic in your L<alienfile>.

 configure {
   # normally the Build::Copy plugin will insert itself
   # as a config requires, but since it is only used
   # on some platforms, you will want to explicitly
   # require it in your alienfile in case you build your
   # alien dist on a platform that doesn't use it.
   requires 'Alien::Build::Plugin::Build::Copy';
 };

 build {
   ...
   if($^O eq 'linux')
   {
     start_url 'http://example.com/binary-blob-linux.tar.gz';
     plugin 'Download';
     plugin 'Extract' => 'tar.gz';
     plugin 'Build::Copy';
   }
   else
   {
     start_url 'http://example.com/source.tar.gz';
     plugin 'Download';
     plugin 'Extract' => 'tar.gz';
     plugin 'Build::Autoconf';
   }
 };

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->add_requires( configure => __PACKAGE__() => 0);

  if($^O eq 'MSWin32')
  {
    $meta->register_hook(build => sub {
      my($build) = @_;
      my $stage = path($build->install_prop->{stage})->canonpath;
      $build->system("xcopy . $stage /E");
    });
  }
  else
  {
    $meta->register_hook(build => [
      'cp -aR * %{.install.stage}',  # TODO: some platforms might not support -a
                                     # I think most platforms will support -r
    ]);
  }
}

1;
