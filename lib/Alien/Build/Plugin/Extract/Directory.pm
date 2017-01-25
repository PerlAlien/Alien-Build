package Alien::Build::Plugin::Extract::Directory;

use strict;
use warnings;
use Alien::Build::Plugin;
use Alien::Build::Util qw( _mirror );
use Path::Tiny ();

# ABSTRACT: Plugin to extract a downloaded directory to a build directory
# VERSION

sub init
{
  my($self, $meta) = @_;
  
  $meta->register_hook(
    extract => sub {
      my($build, $src) = @_;
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
