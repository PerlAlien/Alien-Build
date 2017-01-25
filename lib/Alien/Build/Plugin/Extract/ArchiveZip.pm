package Alien::Build::Plugin::Extract::ArchiveZip;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to extract a tarball using Archive::Tar
# VERSION

has 'format' => 'zip';

=head1 METHODS

=head2 handles

 Alien::Build::Plugin::Extract::ArchiveZip->handles($ext);
 $plugin->handles($ext);

Returns true if the plugin is able to handle the archive of the
given format.

=cut

sub handles
{
  my($class, $ext) = @_;
  
  return 1 if $ext eq 'zip';
  
  return;
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('share' => 'Archive::Zip' => 0);
  
  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;
      my $zip = Archive::Zip->new;
      $zip->read($src);
      $zip->extractTree;
    }
  );
}

1;
