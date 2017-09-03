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
        };
      }
      else
      {
        return {
          type => 'list',
          list => [
            map { { filename => "foo-$_.tar.gz", url => "file://localhost/foo-$_.tar.gz" } } @{ $self->versions },
          ],
        }
      }
    },
  );
}

1;
