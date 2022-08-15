use Test2::V0 -no_srand => 1;
use Test::Alien::Build;
use Path::Tiny qw( path );

alien_subtest 'http html' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
    plugin 'Decode::HTML';
    plugin 'Fetch::FauxHTTP', url => 'http://foo.test', style => 'html';
    plugin 'Prefer::SortVersions';
  };

  alienfile_skip_if_missing_prereqs;
  alien_download_ok;

  is
    path($build->install_prop->{download}),
    object {
      call basename  => 'foo-1.01.tar.gz';
      call slurp_raw => 'tarball 1.01';
    },
    'downloaded 1.01';

};

alien_subtest 'http html' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
    plugin 'Fetch::FauxHTTP', url => 'http://foo.test', style => 'list';
    plugin 'Prefer::SortVersions';
  };

  alienfile_skip_if_missing_prereqs;
  alien_download_ok;

  is
    path($build->install_prop->{download}),
    object {
      call basename  => 'foo-1.01.tar.gz';
      call slurp_raw => 'tarball 1.01';
    },
    'downloaded 1.01';

};

alien_subtest 'https html' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
    plugin 'Decode::HTML';
    plugin 'Fetch::FauxHTTP', url => 'https://foo.test', style => 'html';
    plugin 'Prefer::SortVersions';
  };

  alienfile_skip_if_missing_prereqs;
  alien_download_ok;

  is
    path($build->install_prop->{download}),
    object {
      call basename  => 'foo-1.00.tar.gz';
      call slurp_raw => 'tarball 1.00';
    },
    'downloaded 1.01';

};

alien_subtest 'https html' => sub {

  my $build = alienfile_ok q{
    use alienfile;
    probe sub { 'share' };
    plugin 'Fetch::FauxHTTP', url => 'https://foo.test', style => 'list';
    plugin 'Prefer::SortVersions';
  };

  alienfile_skip_if_missing_prereqs;
  alien_download_ok;

  is
    path($build->install_prop->{download}),
    object {
      call basename  => 'foo-1.00.tar.gz';
      call slurp_raw => 'tarball 1.00';
    },
    'downloaded 1.01';

};

done_testing;

package
  Alien::Build::Plugin::Fetch::FauxHTTP;

use Alien::Build::Plugin;

BEGIN {
  has '+url'  => '';
  has 'style' => 'html';
}

sub init
{
  my($self, $meta) = @_;

  $meta->prop->{start_url} ||= $self->url;

  $meta->register_hook( fetch => sub {
    my($build, $url) = @_;

    $url ||= $self->url;

    if($url =~ m{^https?://foo\.test/?$})
    {
      if($self->style eq 'html')
      {
        return {
          type    => 'html',
          base    => "$url",
          content => q{
            <html><head><title>my listing</title></head><body><ul>
              <li><a href="foo-1.00.tar.gz">foo-1.00.tar.gz</a>
              <li><a href="http://foo.test/foo-1.01.tar.gz">foo-1.01.tar.gz</a>
            </ul></body></html>
          },
        };
      }

      elsif($self->style eq 'list')
      {
        return {
          type => 'list',
          list => [
            { filename => 'foo-1.00.tar.gz', url => 'https://foo.test/foo-1.00.tar.gz' },
            { filename => 'foo-1.01.tar.gz', url => 'http://foo.test/foo-1.01.tar.gz' },
          ],
        };
      }

      else
      {
        die 'oops 1';
      }

    }

    elsif($url =~ m{https?://foo\.test/foo-1\.00\.tar\.gz$})
    {
      return {
        type => 'file',
        filename => 'foo-1.00.tar.gz',
        content => 'tarball 1.00',
      };
    }

    elsif($url =~ m{https?://foo\.test/foo-1\.01\.tar\.gz$})
    {
      return {
        type => 'file',
        filename => 'foo-1.01.tar.gz',
        content => 'tarball 1.01',
      };
    }

    die "oops 2 $url";
  });
}
