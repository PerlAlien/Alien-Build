package Alien::Build::Plugin::Core::Tail;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Core tail setup plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin does some core tail setup for you.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;

  if($meta->prop->{out_of_source})
  {
    $meta->add_requires('configure' => 'Alien::Build' => '1.08');
  }
}

1;
