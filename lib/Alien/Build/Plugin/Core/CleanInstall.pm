package Alien::Build::Plugin::Core::CleanInstall;

use strict;
use warnings;
use Alien::Build::Plugin;
use Path::Tiny ();

# ABSTRACT: Implementation for clean_install hook.
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin implements the default C<clean_install> hook.
You shouldn't use it directly.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->default_hook(
    clean_install => sub {
      my($build) = @_;
      my $root = Path::Tiny->new(
        $build->runtime_prop->{prefix}
      );
      foreach my $child ($root->children)
      {
        if($child->basename eq '_alien')
        {
          $build->log("keeping  $child");
        }
        else
        {
          $build->log("removing $child");
          $child->remove_tree;
        }
      }
    }
  );
}

1;
