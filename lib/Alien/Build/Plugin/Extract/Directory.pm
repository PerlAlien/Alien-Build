package Alien::Build::Plugin::Extract::Directory;

use strict;
use warnings;
use Alien::Build::Plugin;
use Alien::Build::Util qw( _mirror );
use Path::Tiny ();

# ABSTRACT: Plugin to extract a downloaded directory to a build directory
# VERSION

has 'format' => 'd';

=head1 METHODS

=head2 handles

 Alien::Build::Plugin::Extract::Directory->handles($ext);
 $plugin->handles($ext);

Returns true if the plugin is able to handle the archive of the
given format.  Only returns true for C<d> (for directory).

=cut

sub handles
{
  my($class, $ext) = @_;
  $ext eq 'd' ? 1 : ();
}

sub init
{
  my($self, $meta) = @_;
  
  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;
      die "not a directory: $src" unless -d $src;
      my $dst = Path::Tiny::path('.')->absolute;
      # Please note: _mirror and Alien::Build::Util are ONLY
      # allowed to be used by core plugins.  If you are writing
      # a non-core plugin it may be removed.  That is why it
      # is private.
      _mirror $src => $dst, { verbose => 1 };
    }
  );
}

1;
