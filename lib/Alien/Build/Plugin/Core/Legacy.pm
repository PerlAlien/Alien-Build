package Alien::Build::Plugin::Core::Legacy;

use strict;
use warnings;
use 5.008004;
use Alien::Build::Plugin;

# ABSTRACT: Core Alien::Build plugin to maintain compatibility with legacy Alien::Base
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin provides some compatibility with the legacy L<Alien::Base::ModuleBuild>
interfaces.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->after_hook(
    $_ => sub {
      my($build) = @_;

      $build->log("adding legacy hash to config");

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
    }
  ) for qw( gather_system gather_share );
}

1;
