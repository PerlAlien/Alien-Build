package Alien::Build::Plugin::Download::Foo;

use strict;
use warnings;
use Alien::Build::Plugin;

sub init
{
  my($self,$meta) = @_;

  $meta->prop->{check_digest} = 1;
  $meta->prop->{digest} = { '*' => [ FAKE => 'deadbeaf' ] };

  $meta->apply_plugin('Download::Negotiate', url => 'corpus/dist/foo-1.00.tar');
  $meta->apply_plugin('Extract::ArchiveTar');
  $meta->apply_plugin('Test::Mock', check_digest => 1);
  $meta->register_hook(probe => sub { 'share' });
}

1;
