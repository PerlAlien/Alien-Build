package Alien::Build::Plugin::Core::Override;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Core override plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin implements the C<ALIEN_INSTALL_TYPE> environment variable.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;
  
  $meta->default_hook(
    override => sub {
      my($build) = @_;
      return $ENV{ALIEN_INSTALL_TYPE} || '';
    },
  );
}

1;
