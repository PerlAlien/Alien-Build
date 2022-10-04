package Alien::Build::Plugin::Extract::File;

use strict;
use warnings;
use 5.008004;
use Alien::Build::Plugin;
use Alien::Build::Util qw( _mirror );
use Path::Tiny ();

# ABSTRACT: Plugin to extract a downloaded file to a build directory
# VERSION

=head1 SYNOPSIS

 use alienfile;
 plugin 'Extract::File';

=head1 DESCRIPTION

Some Download or Fetch plugins may produce a single file (usually an executable)
instead of an archive file.  This plugin is used to mirror the file from
the Download step into a fresh directory in the Extract step.

=head1 PROPERTIES

=head2 format

Should always set to C<f> (for file).

=cut

has '+format' => 'f';

=head1 METHODS

=head2 handles

 Alien::Build::Plugin::Extract::File->handles($ext);
 $plugin->handles($ext);

Returns true if the plugin is able to handle the archive of the
given format.  Only returns true for C<f> (for file).

=cut

sub handles
{
  my(undef, $ext) = @_;
  $ext eq 'f' ? 1 : ();
}

=head2 available

 Alien::Build::Plugin::Extract::File->available($ext);
 $plugin->available($ext);

Returns true if the plugin can extract the given format with
what is already installed.

=cut

sub available
{
  my(undef, $ext) = @_;
  __PACKAGE__->handles($ext);
}

sub init
{
  my($self, $meta) = @_;

  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;

      die "not a file: $src" unless -f $src;

      $src = Path::Tiny->new($src)->absolute->parent;;

      my $dst = Path::Tiny->new('.')->absolute;
      # Please note: _mirror and Alien::Build::Util are ONLY
      # allowed to be used by core plugins.  If you are writing
      # a non-core plugin it may be removed.  That is why it
      # is private.

      $build->log("extracting $src => $dst");
      _mirror $src => $dst, { verbose => 1 };
    }
  );
}

1;

=head1 SEE ALSO

L<Alien::Build::Plugin::Extract::Negotiate>, L<Alien::Build::Plugin::Extract::File>, L<Alien::Build>, L<alienfile>, L<Alien::Build::MM>, L<Alien>

=cut
