package Alien::Build::Plugin::Fetch::Foo;

use strict;
use warnings;
use Alien::Build::Plugin;

has '+versions' => undef;

sub init
{
  my($self, $meta) = @_;
  $meta->register_hook(
    probe => sub { 'share' },
  );
  $meta->prop->{start_url} = 'file://localhost/';
  $meta->register_hook(
    fetch => sub {
      my($build, $url) = @_;
      $build->log("url = @{[ $url || 'undef' ]}");
      if(defined $url)
      {
        my($filename) = $url =~ m{([^/]*)$};
        return {
          type     => 'file',
          filename => $filename,
          content  => "data:$filename",
          protocol => 'file',
        };
      }
      else
      {
        return {
          type => 'list',
          list => [
            map { { filename => "foo-$_.tar.gz", url => "file://localhost/foo-$_.tar.gz" } } @{ $self->versions },
          ],
          protocol => 'file',
        }
      }
    },
  );
}

1;
