package Alien::Build::Plugin::Core::Legacy;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Core Alien::Build plugin to maintain compatibility with legacy Alien::Base
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin provides some compatibility with the legacy L<Alien::Build::ModuleBuild>
interfaces.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;
  
  $meta->default_hook(
    $_ => sub {},
  ) for qw( gather_system gather_share );
  
  $meta->around_hook(
    $_ => sub {
      my($orig, $build) = @_;
      
      my $ret = $orig->($build);
      
      my $runtime = $build->runtime_prop;
      
      if($runtime->{cflags} && ! defined $runtime->{cflags_static})
      {
        $runtime->{cflags_static} = $runtime->{cflags};
      }

      if($runtime->{libs} && ! defined $runtime->{libs_static})
      {
        $runtime->{libs_static} = $runtime->{libs};
      }
      
      $runtime->{legacy}->{finished_installing} = 1;
      $runtime->{legacy}->{install_type}        = $runtime->{install_type};
      $runtime->{legacy}->{version}             = $runtime->{version};
      $runtime->{legacy}->{original_prefix}     = $runtime->{prefix};
      
      $ret;
    }
  ) for qw( gather_system gather_share );
}

1;
