package Alien::Build::Plugin::Extract::ArchiveTar;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Plugin to extract a tarball using Archive::Tar
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Extract::ArchiveTar' => (
   format => 'tar.gz',
 );

=head1 DESCRIPTION

Note: in most case you will want to use L<Alien::Build::Plugin::Extract::Negotiate>
instead.  It picks the appropriate Extract plugin based on your platform and environment.
In some cases you may need to use this plugin directly instead.

This plugin extracts from an archive in tarball format (optionally compressed by either
gzip or bzip2) using L<Archive::Tar>.

=head1 PROPERTIES

=head2 format

Gives a hint as to the expected format.  This helps make sure the prerequisites are set
correctly, since compressed archives require extra Perl modules to be installed.

=cut

has '+format' => 'tar';

=head1 METHODS

=head2 handles

 Alien::Build::Plugin::Extract::ArchiveTar->handles($ext);
 $plugin->handles($ext);

Returns true if the plugin is able to handle the archive of the
given format.

=cut

sub handles
{
  my($class, $ext) = @_;
  
  return 1 if $ext =~ /^(tar|tar.gz|tar.bz2|tbz|taz)$/;
  
  return;
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->add_requires('share' => 'Archive::Tar' => 0);
  if($self->format eq 'tar.gz' || $self->format eq 'tgz')
  {
    $meta->add_requires('share' => 'IO::Zlib' => 0);
  }
  elsif($self->format eq 'tar.bz2' || $self->format eq 'tbz')
  {
    $meta->add_requires('share' => 'IO::Uncompress::Bunzip2' => 0);
    $meta->add_requires('share' => 'IO::Compress::Bzip2' => 0);
  }
  
  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;
      my $tar = Archive::Tar->new;
      $tar->read($src);
      $tar->extract;
    }
  );
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Extract::Negotiate>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
