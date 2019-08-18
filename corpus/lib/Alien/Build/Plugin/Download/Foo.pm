package Alien::Build::Plugin::Download::Foo;

use strict;
use warnings;
use Alien::Build::Plugin;

sub init
{
  my($self,$meta) = @_;

  require Alien::Build::Plugin::Download::Negotiate;
  require Alien::Build::Plugin::Extract::ArchiveTar;

  Alien::Build::Plugin::Download::Negotiate->new(url => 'corpus/dist/foo-1.00.tar')->init($meta);
  Alien::Build::Plugin::Extract::ArchiveTar->new->init($meta);

  $meta->register_hook(probe => sub { 'share' });
}

1;
