package Alien::Build::Plugin::Core::Setup;

use strict;
use warnings;
use Alien::Build::Plugin;
use Config;

# ABSTRACT: Core setup plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin does some core setup for you.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut
sub init
{
  my($self, $meta) = @_;
  
  if($^O eq 'MSWin32' && $Config{cc} =~ /cl(\.exe)?$/i)
  {
    $meta->prop->{platform}->{compiler_type} = 'microsoft';
  }
  else
  {
    $meta->prop->{platform}->{compiler_type} = 'unix';
  }
}

1;
