package Alien::Build::Plugin::Core::FFI;

use strict;
use warnings;
use Alien::Build::Plugin;

# ABSTRACT: Core FFI plugin
# VERSION

=head1 SYNOPSIS

 use alienfile;
 # already loaded

=head1 DESCRIPTION

This plugin helps make the build_ffi work.  You should not
need to interact with it directly.

=head1 SEE ALSO

L<Alien::Build>, L<Alien::Base::ModuleBuild>

=cut

sub init
{
  my($self, $meta) = @_;

  $meta->default_hook(
    $_ => sub {},
  ) for qw( build_ffi gather_ffi );

  $meta->prop->{destdir_ffi_filter} = '^dynamic';

}

1;
